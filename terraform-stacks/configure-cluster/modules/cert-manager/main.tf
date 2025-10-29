terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
    }
  }
}

# Only setup cert-manager if DNS zone is available
locals {
  enable_tls = var.dns_zone_ocid != ""
}

# ============================================================================
# A. Install cert-manager via OpenShift Operator
# ============================================================================

# Step 1: Create namespace for cert-manager operator
resource "kubernetes_namespace_v1" "cert_manager_operator" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name = "cert-manager-operator"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# Step 2: Create OperatorGroup - tells OLM which namespaces the operator watches
resource "kubectl_manifest" "cert_manager_operator_group" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: cert-manager-operator
      namespace: cert-manager-operator
    spec:
      targetNamespaces:
        - cert-manager-operator
  YAML

  depends_on = [kubernetes_namespace_v1.cert_manager_operator]
}

# Step 3: Subscribe to cert-manager operator from Red Hat operators catalog
resource "kubectl_manifest" "cert_manager_subscription" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: openshift-cert-manager-operator
      namespace: cert-manager-operator
    spec:
      channel: stable-v1
      installPlanApproval: Automatic
      name: openshift-cert-manager-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      startingCSV: cert-manager-operator.v1.17.0
  YAML

  depends_on = [kubectl_manifest.cert_manager_operator_group]
}

# Wait for cert-manager operator to deploy cert-manager
# The OpenShift operator needs significant time to:
# 1. Deploy the cert-manager operator (creates operator pod in cert-manager-operator namespace)
# 2. Operator creates cert-manager namespace
# 3. Operator installs cert-manager pods (cert-manager, cert-manager-webhook, cert-manager-cainjector)
# 4. Operator installs CRDs (Certificate, Issuer, ClusterIssuer, etc.)
# 5. cert-manager webhook service must be FULLY READY before creating any Issuer resources
# 6. cert-manager-webhook pod must be running and its service must be responding
# Using 10 minutes to ensure cert-manager is fully operational in ORM environment
resource "time_sleep" "wait_for_cert_manager_operator" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "10m"

  depends_on = [
    kubectl_manifest.cert_manager_subscription,
    kubectl_manifest.cert_manager_operator_group
  ]
}

# ============================================================================
# B. Deploy OCI DNS webhook
# ============================================================================

# Create namespace for webhook
resource "kubernetes_namespace_v1" "oci_webhook" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name = "cert-manager-webhook-oci"
  }

  depends_on = [time_sleep.wait_for_cert_manager_operator]
}

# Create ServiceAccount for OCI DNS webhook
resource "kubernetes_service_account_v1" "oci_webhook" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name      = "cert-manager-webhook-oci"
    namespace = kubernetes_namespace_v1.oci_webhook[0].metadata[0].name
    labels = {
      "app" = "cert-manager-webhook-oci"
    }
  }
}

# Grant the OCI webhook service account permission to use hostnetwork SCC
# This is REQUIRED for Instance Principal authentication to access the metadata service at 169.254.169.254
resource "kubectl_manifest" "oci_webhook_scc" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: security.openshift.io/v1
    kind: SecurityContextConstraints
    metadata:
      name: cert-manager-webhook-oci-hostnetwork
    allowHostDirVolumePlugin: false
    allowHostIPC: false
    allowHostNetwork: true
    allowHostPID: false
    allowHostPorts: true
    allowPrivilegeEscalation: false
    allowPrivilegedContainer: false
    allowedCapabilities: null
    defaultAddCapabilities: null
    fsGroup:
      type: MustRunAs
    readOnlyRootFilesystem: false
    requiredDropCapabilities:
      - ALL
    runAsUser:
      type: MustRunAsRange
    seLinuxContext:
      type: MustRunAs
    supplementalGroups:
      type: RunAsAny
    users:
      - system:serviceaccount:${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}:cert-manager-webhook-oci
    volumes:
      - configMap
      - downwardAPI
      - emptyDir
      - persistentVolumeClaim
      - projected
      - secret
  YAML

  depends_on = [kubernetes_service_account_v1.oci_webhook]
}

# Create ClusterRole for OCI DNS webhook
resource "kubectl_manifest" "oci_webhook_clusterrole" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: cert-manager-webhook-oci
    rules:
      - apiGroups:
          - ""
        resources:
          - "secrets"
        verbs:
          - "get"
          - "list"
          - "watch"
      - apiGroups:
          - "flowcontrol.apiserver.k8s.io"
        resources:
          - "prioritylevelconfigurations"
          - "flowschemas"
        verbs:
          - "list"
          - "watch"
      - apiGroups:
          - "authorization.k8s.io"
        resources:
          - "subjectaccessreviews"
        verbs:
          - "create"
  YAML

  depends_on = [kubernetes_namespace_v1.oci_webhook]
}

# Create ClusterRoleBinding for OCI DNS webhook
resource "kubectl_manifest" "oci_webhook_clusterrolebinding" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: cert-manager-webhook-oci
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cert-manager-webhook-oci
    subjects:
      - kind: ServiceAccount
        name: cert-manager-webhook-oci
        namespace: ${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}
  YAML

  depends_on = [kubectl_manifest.oci_webhook_clusterrole]
}

# Create ClusterRole for cert-manager to use OCI webhook
# This allows cert-manager to create the OCI webhook custom resources for DNS-01 challenges
resource "kubectl_manifest" "cert_manager_oci_webhook_role" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: cert-manager:webhook:oci
    rules:
      - apiGroups:
          - "acme.oci.oraclecloud.com"
        resources:
          - "oci"
        verbs:
          - "create"
  YAML

  depends_on = [time_sleep.wait_for_cert_manager_operator]
}

# Create ClusterRoleBinding to grant cert-manager permission to use OCI webhook
resource "kubectl_manifest" "cert_manager_oci_webhook_rolebinding" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: cert-manager:webhook:oci
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cert-manager:webhook:oci
    subjects:
      - kind: ServiceAccount
        name: cert-manager
        namespace: cert-manager
  YAML

  depends_on = [kubectl_manifest.cert_manager_oci_webhook_role]
}

# Create Deployment for OCI DNS webhook
resource "kubernetes_deployment_v1" "oci_webhook" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name      = "cert-manager-webhook-oci"
    namespace = kubernetes_namespace_v1.oci_webhook[0].metadata[0].name
    labels = {
      app = "cert-manager-webhook-oci"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cert-manager-webhook-oci"
      }
    }

    template {
      metadata {
        labels = {
          app = "cert-manager-webhook-oci"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.oci_webhook[0].metadata[0].name
        # CRITICAL: hostNetwork required for Instance Principal to access OCI metadata service (169.254.169.254)
        host_network = true
        # Use control plane DNS to avoid conflicts with host network
        dns_policy = "ClusterFirstWithHostNet"

        container {
          name  = "webhook"
          image = "ghcr.io/giovannicandido/cert-manager-webhook-oci:build-pipeline"

          args = [
            "--secure-port=8443",
            "--tls-cert-file=/tls/tls.crt",
            "--tls-private-key-file=/tls/tls.key",
            "--v=2",
          ]

          port {
            name           = "https"
            container_port = 8443
            protocol       = "TCP"
          }

          env {
            name  = "GROUP_NAME"
            value = var.webhook_group_name
          }

          env {
            name  = "OCI_USE_INSTANCE_PRINCIPAL"
            value = "true"
          }

          env {
            name  = "OCI_COMPARTMENT_OCID"
            value = var.compartment_ocid
          }

          volume_mount {
            name       = "certs"
            mount_path = "/tls"
            read_only  = true
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }

        volume {
          name = "certs"
          secret {
            secret_name = "cert-manager-webhook-oci-tls"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account_v1.oci_webhook,
    time_sleep.wait_for_webhook_cert
  ]
}

# Create Service for OCI DNS webhook
resource "kubernetes_service_v1" "oci_webhook" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name      = "cert-manager-webhook-oci"
    namespace = kubernetes_namespace_v1.oci_webhook[0].metadata[0].name
  }

  spec {
    selector = {
      app = "cert-manager-webhook-oci"
    }

    port {
      name        = "https"
      port        = 443
      target_port = "https"
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment_v1.oci_webhook]
}

# Create self-signed Issuer for webhook TLS certificate
resource "kubectl_manifest" "oci_webhook_issuer" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: cert-manager-webhook-oci-ca
      namespace: ${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}
    spec:
      selfSigned: {}
  YAML

  depends_on = [
    time_sleep.wait_for_cert_manager_operator,
    kubernetes_namespace_v1.oci_webhook,
    kubernetes_service_account_v1.oci_webhook
  ]
}

# Create Certificate for webhook TLS
resource "kubectl_manifest" "oci_webhook_cert" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: cert-manager-webhook-oci-tls
      namespace: ${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}
    spec:
      secretName: cert-manager-webhook-oci-tls
      dnsNames:
        - cert-manager-webhook-oci
        - cert-manager-webhook-oci.${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}
        - cert-manager-webhook-oci.${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}.svc
      issuerRef:
        name: cert-manager-webhook-oci-ca
        kind: Issuer
  YAML

  depends_on = [kubectl_manifest.oci_webhook_issuer]
}

# Wait for webhook certificate to be issued and secret created
resource "time_sleep" "wait_for_webhook_cert" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "60s"

  depends_on = [kubectl_manifest.oci_webhook_cert]
}

# Create APIService for webhook
resource "kubectl_manifest" "oci_webhook_apiservice" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: apiregistration.k8s.io/v1
    kind: APIService
    metadata:
      name: v1alpha1.${var.webhook_group_name}
      annotations:
        cert-manager.io/inject-ca-from: ${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}/cert-manager-webhook-oci-tls
    spec:
      group: ${var.webhook_group_name}
      groupPriorityMinimum: 1000
      versionPriority: 15
      service:
        name: cert-manager-webhook-oci
        namespace: ${kubernetes_namespace_v1.oci_webhook[0].metadata[0].name}
      version: v1alpha1
  YAML

  depends_on = [
    kubectl_manifest.oci_webhook_cert,
    kubernetes_service_v1.oci_webhook
  ]
}

# Wait for webhook to be fully ready
resource "time_sleep" "wait_for_webhook" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "60s"

  depends_on = [kubectl_manifest.oci_webhook_apiservice]
}

# ============================================================================
# C. Create Let's Encrypt Staging ClusterIssuer
# ============================================================================

resource "kubectl_manifest" "letsencrypt_staging_issuer" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-staging
    spec:
      acme:
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        email: ${var.letsencrypt_email}
        privateKeySecretRef:
          name: letsencrypt-staging-account-key
        solvers:
        - dns01:
            webhook:
              groupName: ${var.webhook_group_name}
              solverName: oci
              config:
                ociZoneOCID: ${var.dns_zone_ocid}
                compartmentOCID: ${var.compartment_ocid}
                useInstancePrincipal: true
  YAML

  depends_on = [time_sleep.wait_for_webhook]
}

# ============================================================================
# D. Create Let's Encrypt Production ClusterIssuer
# ============================================================================

resource "kubectl_manifest" "letsencrypt_prod_issuer" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.letsencrypt_email}
        privateKeySecretRef:
          name: letsencrypt-prod-account-key
        solvers:
        - dns01:
            webhook:
              groupName: ${var.webhook_group_name}
              solverName: oci
              config:
                ociZoneOCID: ${var.dns_zone_ocid}
                compartmentOCID: ${var.compartment_ocid}
                useInstancePrincipal: true
  YAML

  depends_on = [time_sleep.wait_for_webhook]
}

# ============================================================================
# E. Create wildcard certificate for apps ingress
# ============================================================================


# Request wildcard certificate for apps ingress
resource "kubectl_manifest" "apps_wildcard_cert" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: apps-wildcard-cert
      namespace: openshift-ingress
    spec:
      secretName: apps-wildcard-tls
      duration: 2160h # 90 days
      renewBefore: 720h # 30 days
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      commonName: "*.${var.cluster_domain}"
      dnsNames:
        - "*.${var.cluster_domain}"
  YAML

  depends_on = [
    kubectl_manifest.letsencrypt_prod_issuer
  ]
}

# ============================================================================
# F. Patch IngressController to use wildcard certificate
# ============================================================================

# Wait for apps certificate to be issued
resource "time_sleep" "wait_for_apps_certificate" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "5m"

  depends_on = [kubectl_manifest.apps_wildcard_cert]
}

# Patch IngressController to use the wildcard certificate
resource "kubectl_manifest" "ingress_default_cert" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: operator.openshift.io/v1
    kind: IngressController
    metadata:
      name: default
      namespace: openshift-ingress-operator
    spec:
      defaultCertificate:
        name: apps-wildcard-tls
  YAML

  depends_on = [time_sleep.wait_for_apps_certificate]
}

# ============================================================================
# G. Create certificate for API server
# ============================================================================


# Request certificate for API server
resource "kubectl_manifest" "api_server_cert" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: api-server-cert
      namespace: openshift-config
    spec:
      secretName: api-server-tls
      duration: 2160h # 90 days
      renewBefore: 720h # 30 days
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      commonName: "api.${var.cluster_base_domain}"
      dnsNames:
        - "api.${var.cluster_base_domain}"
  YAML

  depends_on = [
    kubectl_manifest.letsencrypt_prod_issuer
  ]
}

# ============================================================================
# H. Patch APIServer to use certificate
# ============================================================================

# Wait for API certificate to be issued
resource "time_sleep" "wait_for_api_certificate" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "5m"

  depends_on = [kubectl_manifest.api_server_cert]
}

# Patch APIServer to use the certificate
resource "kubectl_manifest" "api_server_config" {
  count = local.enable_tls ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: config.openshift.io/v1
    kind: APIServer
    metadata:
      name: cluster
    spec:
      servingCerts:
        namedCertificates:
          - names:
              - "api.${var.cluster_base_domain}"
            servingCertificate:
              name: api-server-tls
  YAML

  depends_on = [time_sleep.wait_for_api_certificate]
}

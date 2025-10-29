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

# Subscribe to cert-manager operator from Red Hat operators catalog
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
      name: openshift-cert-manager-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      installPlanApproval: Automatic
  YAML
}

# Create namespace for cert-manager operator
resource "kubernetes_namespace_v1" "cert_manager_operator" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name = "cert-manager-operator"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# Wait for cert-manager operator to be deployed
resource "time_sleep" "wait_for_cert_manager_operator" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "120s"

  depends_on = [kubectl_manifest.cert_manager_subscription]
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

  depends_on = [kubernetes_service_account_v1.oci_webhook]
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

  depends_on = [time_sleep.wait_for_cert_manager_operator]
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

# Create openshift-ingress namespace if it doesn't exist
resource "kubernetes_namespace_v1" "openshift_ingress" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name = "openshift-ingress"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

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
    kubectl_manifest.letsencrypt_prod_issuer,
    kubernetes_namespace_v1.openshift_ingress
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

# Create openshift-config namespace if it doesn't exist
resource "kubernetes_namespace_v1" "openshift_config" {
  count = local.enable_tls ? 1 : 0

  metadata {
    name = "openshift-config"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

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
    kubectl_manifest.letsencrypt_prod_issuer,
    kubernetes_namespace_v1.openshift_config
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

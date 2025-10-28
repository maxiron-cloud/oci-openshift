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
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
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

# Fetch cert-manager installation manifest
data "http" "cert_manager_manifest" {
  count = local.enable_tls ? 1 : 0
  url   = "https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.yaml"
}

# Create a temporary file with cert-manager manifest
resource "local_file" "cert_manager_temp" {
  count    = local.enable_tls ? 1 : 0
  content  = data.http.cert_manager_manifest[0].response_body
  filename = "${path.module}/cert-manager-temp.yaml"
}

# Use kubectl_path_documents to parse the manifest file
data "kubectl_path_documents" "cert_manager_manifests" {
  count   = local.enable_tls ? 1 : 0
  pattern = "${path.module}/cert-manager-temp.yaml"
  
  depends_on = [local_file.cert_manager_temp]
}

# Apply cert-manager manifests using for_each which doesn't have the count limitation
resource "kubectl_manifest" "cert_manager" {
  for_each = local.enable_tls ? data.kubectl_path_documents.cert_manager_manifests[0].manifests : {}
  
  yaml_body = each.value

  server_side_apply = true
  wait              = true
}

# Create cert-manager namespace explicitly first (if not created by manifest)
resource "kubernetes_namespace_v1" "cert_manager" {
  count = local.enable_tls ? 1 : 0
  
  metadata {
    name = "cert-manager"
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }

  depends_on = [kubectl_manifest.cert_manager]
}

# Wait for cert-manager webhook to be ready
resource "time_sleep" "wait_for_cert_manager" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "90s"

  depends_on = [kubectl_manifest.cert_manager]
}

# Fetch OCI DNS webhook manifest
data "http" "oci_dns_webhook_manifest" {
  count = local.enable_tls ? 1 : 0
  url   = "https://github.com/dn13/cert-manager-webhook-oci/releases/download/v${var.oci_dns_webhook_version}/rendered-manifest.yaml"
}

# Create a temporary file with OCI DNS webhook manifest
resource "local_file" "oci_webhook_temp" {
  count    = local.enable_tls ? 1 : 0
  content  = data.http.oci_dns_webhook_manifest[0].response_body
  filename = "${path.module}/oci-webhook-temp.yaml"
}

# Use kubectl_path_documents to parse the webhook manifest file
data "kubectl_path_documents" "oci_webhook_manifests" {
  count   = local.enable_tls ? 1 : 0
  pattern = "${path.module}/oci-webhook-temp.yaml"
  
  depends_on = [local_file.oci_webhook_temp]
}

# Apply OCI DNS webhook manifests using for_each
resource "kubectl_manifest" "oci_dns_webhook" {
  for_each = local.enable_tls ? data.kubectl_path_documents.oci_webhook_manifests[0].manifests : {}

  yaml_body = each.value

  server_side_apply = true
  wait              = true

  depends_on = [time_sleep.wait_for_cert_manager]
}

# Wait for OCI DNS webhook to be ready
resource "time_sleep" "wait_for_webhook" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "30s"

  depends_on = [kubectl_manifest.oci_dns_webhook]
}

# Create ConfigMap for OCI DNS webhook to use Instance Principal
resource "kubernetes_config_map_v1" "oci_dns_config" {
  count = local.enable_tls ? 1 : 0
  
  metadata {
    name      = "oci-dns-config"
    namespace = "cert-manager"
  }

  data = {
    use-instance-principal = "true"
    compartment-ocid      = var.dns_compartment_ocid
  }

  depends_on = [kubernetes_namespace_v1.cert_manager]
}

# Create ClusterIssuer for Let's Encrypt production with OCI DNS-01
resource "kubectl_manifest" "letsencrypt_issuer" {
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
              groupName: oci.oraclecloud.com
              solverName: oci
              config:
                ociZoneOCID: ${var.dns_zone_ocid}
                compartmentOCID: ${var.dns_compartment_ocid}
                useInstancePrincipal: true
  YAML

  depends_on = [time_sleep.wait_for_webhook]
}

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

# Request wildcard certificate
resource "kubectl_manifest" "wildcard_cert" {
  count = local.enable_tls ? 1 : 0
  
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: wildcard-tls
      namespace: openshift-ingress
    spec:
      secretName: wildcard-tls-cert
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
    kubectl_manifest.letsencrypt_issuer,
    kubernetes_namespace_v1.openshift_ingress
  ]
}

# Wait for certificate to be issued
resource "time_sleep" "wait_for_certificate" {
  count           = local.enable_tls ? 1 : 0
  create_duration = "5m"

  depends_on = [kubectl_manifest.wildcard_cert]
}

# Patch IngressController to use the certificate
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
        name: wildcard-tls-cert
  YAML

  depends_on = [time_sleep.wait_for_certificate]
}


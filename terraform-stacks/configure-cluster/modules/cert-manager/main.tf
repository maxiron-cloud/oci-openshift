terraform {
  required_version = ">= 1.0"
}

# Fetch cert-manager installation manifest
data "http" "cert_manager_manifest" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.yaml"
}

# Split the manifest into individual resources and apply them
locals {
  # Split the YAML manifest by document separator
  cert_manager_manifests = split("---", data.http.cert_manager_manifest.response_body)
  
  # Filter out empty documents
  cert_manager_docs = [
    for doc in local.cert_manager_manifests : doc
    if trimspace(doc) != ""
  ]
}

# Apply cert-manager manifests
resource "kubectl_manifest" "cert_manager" {
  count     = length(local.cert_manager_docs)
  yaml_body = local.cert_manager_docs[count.index]

  server_side_apply = true
  wait              = true
}

# Create cert-manager namespace explicitly first (if not created by manifest)
resource "kubernetes_namespace_v1" "cert_manager" {
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
  create_duration = "90s"

  depends_on = [kubectl_manifest.cert_manager]
}

# Fetch OCI DNS webhook manifest
data "http" "oci_dns_webhook_manifest" {
  url = "https://github.com/dn13/cert-manager-webhook-oci/releases/download/v${var.oci_dns_webhook_version}/rendered-manifest.yaml"
}

# Split and apply OCI DNS webhook manifests
locals {
  oci_webhook_manifests = split("---", data.http.oci_dns_webhook_manifest.response_body)
  
  oci_webhook_docs = [
    for doc in local.oci_webhook_manifests : doc
    if trimspace(doc) != ""
  ]
}

resource "kubectl_manifest" "oci_dns_webhook" {
  count     = length(local.oci_webhook_docs)
  yaml_body = local.oci_webhook_docs[count.index]

  server_side_apply = true
  wait              = true

  depends_on = [time_sleep.wait_for_cert_manager]
}

# Wait for OCI DNS webhook to be ready
resource "time_sleep" "wait_for_webhook" {
  create_duration = "30s"

  depends_on = [kubectl_manifest.oci_dns_webhook]
}

# Create ConfigMap for OCI DNS webhook to use Instance Principal
resource "kubernetes_config_map_v1" "oci_dns_config" {
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
  metadata {
    name = "openshift-ingress"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# Request wildcard certificate
resource "kubectl_manifest" "wildcard_cert" {
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
  create_duration = "5m"

  depends_on = [kubectl_manifest.wildcard_cert]
}

# Patch IngressController to use the certificate
resource "kubectl_manifest" "ingress_default_cert" {
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


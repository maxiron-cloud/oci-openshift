# Configure OpenShift Cluster on OCI

This Terraform stack provides post-installation configuration for OpenShift clusters deployed on Oracle Cloud Infrastructure (OCI).

## Features

- **Image Registry Configuration**: Configures the internal OpenShift image registry with persistent storage and exposes the default route for external access
- **TLS Certificate Management**: Automatically provisions Let's Encrypt wildcard certificates using cert-manager and OCI DNS-01 challenge validation
- **Extensible Design**: Modular structure allows easy addition of more post-installation configurations

## Prerequisites

1. **OpenShift Cluster**: A deployed OpenShift cluster on OCI (use the `create-cluster` stack with DNS IAM policies enabled)
2. **Kubeconfig File**: Access to the cluster's kubeconfig file
3. **Cluster Access**: Network connectivity to the cluster API endpoint
4. **DNS Zone**: An OCI DNS zone matching your cluster domain with proper NS delegation
5. **IAM Policies**: Control plane nodes must have DNS management permissions (configured in create-cluster stack)
6. **Terraform**: Version >= 1.0

## Obtaining the Kubeconfig

After your OpenShift cluster is installed, you can obtain the kubeconfig:

### For Agent-Based Installer:
```bash
# The kubeconfig is generated during installation
# Location: auth/kubeconfig in your installation directory
export KUBECONFIG=/path/to/auth/kubeconfig
```

### For Assisted Installer:
1. Download the kubeconfig from the Assisted Installer UI
2. Or use the OpenShift CLI to login and generate it:
   ```bash
   oc login https://api.<cluster-name>.<base-domain>:6443
   ```

## Usage

## DNS Zone Requirements

Provide your OCI DNS zone name for TLS certificate management:

**Example:** 
- Cluster domain: `test.oracle.maxiron.cloud`
- DNS zone name to provide: `oracle.maxiron.cloud`
- Wildcard cert issued for: `*.apps.test.oracle.maxiron.cloud`

If DNS zone name is not provided (left empty), cert-manager setup is skipped (image registry still configured).

### **For ORM (Oracle Resource Manager):**

1. **Download your kubeconfig** from the OpenShift cluster
2. **Upload kubeconfig to OCI Object Storage:**
   ```bash
   oci os object put \
     --bucket-name my-bucket \
     --file kubeconfig \
     --name cluster-kubeconfig
   ```
3. **Create a Pre-Authenticated Request (PAR):**
   - In OCI Console: Object Storage → Bucket → Object → Create Pre-Authenticated Request
   - Or CLI:
   ```bash
   oci os preauth-request create \
     --bucket-name my-bucket \
     --object-name cluster-kubeconfig \
     --access-type ObjectRead \
     --time-expires 2025-12-31T23:59:59Z \
     --name kubeconfig-par
   ```
4. **Copy the PAR URL** (looks like: `https://objectstorage.uk-london-1.oraclecloud.com/p/...`)
5. In **ORM Stack Configuration**, paste the PAR URL into the **"Kubeconfig PAR URL"** field
6. Configure other variables and apply

### **For Local Terraform CLI (Alternative):**

If you prefer to run locally without ORM restrictions:

```bash
cd terraform-stacks/configure-cluster
terraform init
terraform apply \
  -var="kubeconfig_par_url=https://objectstorage...../kubeconfig" \
  -var="compartment_ocid=ocid1.compartment.oc1..." \
  -var="letsencrypt_email=cloud@maxiron.com"
```

The stack will automatically:
- Fetch kubeconfig from Object Storage
- Detect your cluster domain from the API server URL
- Find the matching DNS zone in OCI
- Configure the image registry and issue TLS certificates

### Configuration Options

In ORM, you can customize the following settings:

- **Image Registry Storage Size**: Default 100Gi, can be increased (e.g., 200Gi, 500Gi)
- **Storage Class**: Default `oci-bv-immediate`, can use `oci-bv` for WaitForFirstConsumer
- **DNS Compartment**: Leave empty to use cluster compartment, or specify if DNS zone is in different compartment
- **Let's Encrypt Email**: Defaults to `cloud@maxiron.com`, can be changed if needed


## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `kubeconfig_par_url` | PAR URL to fetch kubeconfig from Object Storage | - | Yes |
| `compartment_ocid` | Compartment OCID where cluster exists | - | Yes |
| `dns_compartment_ocid` | Compartment OCID where DNS zone exists | `""` (uses compartment_ocid) | No |
| `dns_zone_name` | OCI DNS zone name (e.g., oracle.maxiron.cloud) | `""` (skips TLS setup) | No |
| `letsencrypt_email` | Email for Let's Encrypt notifications | `cloud@maxiron.com` | No |
| `image_registry_storage_size` | Size of PVC for image registry | `100Gi` | No |
| `image_registry_storage_class` | StorageClass for image registry PVC | `oci-bv-immediate` | No |

## Outputs

| Output | Description |
|--------|-------------|
| `image_registry_pvc_name` | Name of the PVC created for the image registry |
| `image_registry_storage_class` | StorageClass used for the image registry |
| `image_registry_storage_size` | Storage size allocated for the image registry |
| `cluster_domain` | Auto-detected cluster base domain |
| `apps_domain` | Apps domain for wildcard certificate |
| `cert_manager_cluster_issuer` | ClusterIssuer name for Let's Encrypt |
| `wildcard_certificate_secret` | Secret name containing the TLS certificate |
| `dns_zone_ocid` | Auto-detected DNS zone OCID |

## What Gets Configured

### Image Registry

1. **PersistentVolumeClaim**: Creates a 100Gi (default) PVC in the `openshift-image-registry` namespace
2. **Registry Configuration**: 
   - Sets managementState to `Managed`
   - Configures single replica with `Recreate` rollout strategy
   - Schedules on control-plane nodes with appropriate tolerations
   - Enables the default route for external access
3. **Route Exposure**: The default route is automatically created and exposed

After configuration, you can push/pull images using:
```bash
# Get the registry route
oc get route default-route -n openshift-image-registry

# Login to the registry
podman login <registry-route>

# Push an image
podman push <registry-route>/<project>/<image>:<tag>
```

### TLS Certificate Management

1. **cert-manager Installation**: 
   - Deploys cert-manager v1.16.2 with all CRDs, controllers, and webhooks
   - Creates `cert-manager` namespace
   
2. **OCI DNS Webhook**: 
   - Installs cert-manager-webhook-oci for DNS-01 challenge validation
   - Configured to use Instance Principal authentication (no credentials needed)
   - Manages DNS records in your OCI DNS zone

3. **ClusterIssuer**: 
   - Creates `letsencrypt-prod` ClusterIssuer
   - Configured for ACME protocol with Let's Encrypt production environment
   - Uses DNS-01 challenge via OCI DNS webhook

4. **Wildcard Certificate**: 
   - Automatically requests a wildcard certificate for `*.apps.<cluster-domain>`
   - Certificate is stored in `wildcard-tls-cert` secret in `openshift-ingress` namespace
   - Auto-renewal configured 30 days before expiry

5. **Ingress Configuration**: 
   - Patches the default IngressController to use the wildcard certificate
   - All routes automatically use the trusted Let's Encrypt certificate
   - No more browser warnings!

**How It Works:**

```
cert-manager → ClusterIssuer (Let's Encrypt) → Certificate Request → 
DNS-01 Challenge → OCI DNS Webhook → Creates TXT record → 
Let's Encrypt validates → Certificate issued → 
Stored in Secret → IngressController uses certificate
```

**Auto-Detection:**
- Cluster domain extracted from kubeconfig API server URL
- DNS zone automatically found by matching domain name
- No manual OCID lookups required!

## Verifying the Configuration

### Check Image Registry Status

```bash
# Check the registry configuration
oc get configs.imageregistry.operator.openshift.io cluster -o yaml

# Check the PVC
oc get pvc image-registry-storage -n openshift-image-registry

# Check the registry pods
oc get pods -n openshift-image-registry

# Get the registry route
oc get route -n openshift-image-registry
```

### Check cert-manager and Certificates

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check ClusterIssuer status
kubectl get clusterissuer letsencrypt-prod
kubectl describe clusterissuer letsencrypt-prod

# Check Certificate status
kubectl get certificate -n openshift-ingress
kubectl describe certificate wildcard-tls -n openshift-ingress

# Verify certificate details
kubectl get secret wildcard-tls-cert -n openshift-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check IngressController configuration
oc get ingresscontroller default -n openshift-ingress-operator -o yaml

# Test a route - should show valid Let's Encrypt certificate
curl -v https://console-openshift-console.apps.<your-domain>
```

**Certificate Issuance Timeline:**
- cert-manager deployment: ~2 minutes
- DNS-01 challenge: ~2-3 minutes
- Certificate issuance: ~1 minute
- Total: ~5-6 minutes

**Expected States:**
1. Certificate status: `Ready=True`
2. ClusterIssuer status: `Ready=True`
3. Browser: Shows "Secure" with Let's Encrypt certificate

## Module Structure

The stack is organized with a modular structure for easy extension:

```
configure-cluster/
├── main.tf                           # Providers and module orchestration
├── variables.tf                      # Stack-level variables
├── outputs.tf                        # Stack-level outputs
├── schema.yaml                       # ORM compatibility schema
├── version.tf                        # Provider requirements
├── modules/
│   ├── image-registry/              # Image registry configuration
│   │   ├── main.tf                  # PVC and Config resources
│   │   ├── variables.tf             # Module variables
│   │   └── outputs.tf               # Module outputs
│   └── cert-manager/                # TLS certificate management
│       ├── main.tf                  # cert-manager, webhook, issuer, certificate
│       ├── variables.tf             # Module variables
│       └── outputs.tf               # Module outputs
```

## Future Enhancements

This stack is designed to be extended with additional post-installation configurations:

- **Monitoring**: Configure cluster monitoring and alerting
- **Logging**: Set up centralized logging
- **Networking**: Configure network policies and ingress controllers
- **Authentication**: Set up identity providers
- **Certificate Management**: Configure custom certificates

Each feature can be added as a new module under `modules/`.

## Troubleshooting

### Provider Authentication Error
```
Error: Failed to load kubeconfig
```
**Solution**: Ensure the kubeconfig path is correct and the file is readable.

### PVC Stuck in Pending
```
PersistentVolumeClaim is in Pending state
```
**Solution**: Check that the specified StorageClass exists and the CSI driver is running:
```bash
oc get storageclass
oc get pods -n oci-csi
```

### Registry Pod Not Starting
```
Registry pod is in CrashLoopBackOff
```
**Solution**: Check that the PVC is bound and the control-plane nodes are ready:
```bash
oc get pvc -n openshift-image-registry
oc get nodes -l node-role.kubernetes.io/master
```

### Certificate Not Issuing
```
Certificate status shows "False" or stuck in pending
```
**Solutions**:

1. **Check DNS zone exists and is accessible:**
```bash
# Verify DNS zone in OCI Console
# Ensure zone name matches cluster domain
```

2. **Check IAM permissions:**
```bash
# Verify control plane nodes have DNS management permissions
# Policy should include: manage dns-zones, manage dns-records
```

3. **Check cert-manager logs:**
```bash
kubectl logs -n cert-manager -l app=cert-manager
kubectl logs -n cert-manager -l app=webhook
```

4. **Check certificate details:**
```bash
kubectl describe certificate wildcard-tls -n openshift-ingress
# Look for Events section for error messages
```

5. **Verify OCI DNS webhook:**
```bash
kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager-webhook-oci
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager-webhook-oci
```

### DNS Challenge Failed
```
Error: DNS-01 challenge failed
```
**Solutions**:
- Verify DNS zone is ACTIVE in OCI
- Check that NS records are properly delegated
- Ensure Instance Principal has permissions
- Wait 2-3 minutes for DNS propagation

### Rate Limit Exceeded
```
Error: too many certificates already issued
```
**Solution**: Let's Encrypt has rate limits (50 certificates per domain per week). Wait or use staging environment for testing.

## Support

For issues related to:
- **Terraform Stack**: Check the plan/apply output and Terraform state
- **OpenShift Registry**: See [OpenShift Image Registry Documentation](https://docs.openshift.com/container-platform/latest/registry/index.html)
- **OCI Storage**: See [OCI Block Volume Documentation](https://docs.oracle.com/iaas/Content/Block/Concepts/overview.htm)


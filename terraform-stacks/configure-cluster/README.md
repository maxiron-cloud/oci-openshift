# Configure OpenShift Cluster on OCI

This Terraform stack provides post-installation configuration for OpenShift clusters deployed on Oracle Cloud Infrastructure (OCI).

## Features

- **Image Registry Configuration**: Configures the internal OpenShift image registry with persistent storage and exposes the default route for external access
- **Automated TLS Certificate Management**: Installs cert-manager via OpenShift Operator, deploys OCI DNS webhook, and provisions Let's Encrypt certificates for apps ingress (console and applications)
- **DNS-01 Challenge Support**: Enables wildcard certificates using OCI DNS with Instance Principal authentication
- **Extensible Design**: Modular structure allows easy addition of more post-installation configurations

## Prerequisites

1. **OpenShift Cluster**: A deployed OpenShift cluster on OCI (use the `create-cluster` stack with DNS IAM policies enabled)
2. **Kubeconfig File**: Access to the cluster's kubeconfig file
3. **Cluster Access**: Network connectivity to the cluster API endpoint
4. **OCI DNS Zone**: A DNS zone in OCI DNS matching your cluster domain (e.g., oracle.maxiron.cloud for cluster test.oracle.maxiron.cloud)
5. **IAM Policies**: Control plane nodes must have DNS management permissions (automatically configured by create-cluster stack)
6. **Terraform**: Version >= 1.0

## Certificate Management

This stack provides **fully automated TLS certificate management** using:

### How It Works

1. **cert-manager Installation**: Deploys cert-manager via Red Hat OpenShift Operator from the certified operator catalog
2. **OCI DNS Webhook**: Installs [giovannicandido/cert-manager-webhook-oci](https://github.com/giovannicandido/cert-manager-webhook-oci) for DNS-01 challenge validation with `hostNetwork: true` for Instance Principal access
3. **Instance Principal Authentication**: No credentials needed - uses the existing dynamic group IAM policy for control plane nodes to access OCI DNS
4. **Let's Encrypt Integration**: Creates both staging and production ClusterIssuers for certificate management
5. **Automatic Certificate Provisioning**:
   - Wildcard certificate for apps: `*.apps.<cluster-domain>` (covers console and all applications)
6. **Auto-Configuration**: Patches IngressController to use the wildcard certificate
7. **⚠️ API Server Certificate**: Intentionally NOT changed - keeps self-signed certificate from installation to preserve kubeconfig connectivity

### Certificate Issuance Flow

```
1. Certificate resource created for *.apps.<cluster-domain>
2. cert-manager triggers Let's Encrypt ACME challenge
3. OCI DNS webhook creates TXT record in your DNS zone  
4. Let's Encrypt validates domain ownership via DNS
5. Certificate issued and stored in Kubernetes Secret
6. IngressController automatically reloads with new certificate
7. Console and all apps now use valid Let's Encrypt certificate
```

### ⚠️ Important: API Server Certificate

**The API server certificate is intentionally NOT changed by this stack.**

#### Why?
The kubeconfig file from cluster installation contains the original self-signed CA certificate. If we change the API server certificate to use Let's Encrypt:
- ✅ The certificate becomes valid for browsers
- ❌ **But the kubeconfig becomes invalid** (CA mismatch)
- ❌ All `oc` and `kubectl` commands fail
- ❌ Terraform can't destroy the cluster
- ❌ Day 2 operations become impossible

#### What Gets Secured?
- ✅ **Console**: `https://console-openshift-console.apps.<cluster-domain>` → Valid Let's Encrypt cert
- ✅ **All Apps**: `https://*.apps.<cluster-domain>` → Valid Let's Encrypt cert
- ⚠️ **API Server**: `https://api.<cluster-domain>:6443` → Self-signed cert (only accessed by CLI tools, not browsers)

This is the **correct approach for OCI OpenShift clusters** because:
1. Users access the console via browser (gets valid cert) ✅
2. Applications use the apps domain (get valid certs) ✅
3. CLI tools use the API server (work with the original kubeconfig) ✅
4. Infrastructure operations remain functional ✅

### Skipping Certificate Setup

To skip TLS certificate setup entirely and use default self-signed certificates everywhere:
- Leave `dns_zone_name` empty when running the stack
- The stack will only configure the image registry

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


## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `kubeconfig_par_url` | PAR URL to fetch kubeconfig from Object Storage | - | Yes |
| `compartment_ocid` | Compartment OCID where cluster and DNS zone exist | - | Yes |
| `dns_zone_name` | OCI DNS zone name for TLS certificates | `""` (skips TLS) | No |
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
| `apps_domain` | Apps domain for the cluster |
| `staging_cluster_issuer` | Name of Let's Encrypt staging ClusterIssuer |
| `production_cluster_issuer` | Name of Let's Encrypt production ClusterIssuer |
| `apps_certificate_secret` | Secret containing apps wildcard certificate |
| `dns_zone_ocid` | OCI DNS zone OCID being used |
| `dns_zone_name` | DNS zone name provided |

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

### Check cert-manager Operator

```bash
# Check cert-manager operator installation
oc get csv -n cert-manager-operator | grep cert-manager

# Check operator status
oc get pods -n cert-manager-operator

# Verify cert-manager is running
oc get pods -n cert-manager | grep cert-manager
```

### Check OCI DNS Webhook

```bash
# Check webhook deployment
oc get deployment -n cert-manager-webhook-oci

# Check webhook pods
oc get pods -n cert-manager-webhook-oci

# Check webhook logs
oc logs -n cert-manager-webhook-oci -l app=cert-manager-webhook-oci
```

### Check ClusterIssuers

```bash
# List all ClusterIssuers
oc get clusterissuer

# Check staging issuer status
oc describe clusterissuer letsencrypt-staging

# Check production issuer status
oc describe clusterissuer letsencrypt-prod
```

### Check Apps Wildcard Certificate

```bash
# Check certificate status
oc get certificate -n openshift-ingress

# Check detailed certificate information
oc describe certificate apps-wildcard-cert -n openshift-ingress

# Verify certificate is ready
oc get certificate apps-wildcard-cert -n openshift-ingress -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# View certificate details
oc get secret apps-wildcard-tls -n openshift-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check IngressController configuration
oc get ingresscontroller default -n openshift-ingress-operator -o yaml | grep -A 5 defaultCertificate
```

### Check API Server Certificate

```bash
# Check API certificate status
oc get certificate -n openshift-config

# Check detailed certificate information
oc describe certificate api-server-cert -n openshift-config

# Verify certificate is ready
oc get certificate api-server-cert -n openshift-config -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# View certificate details
oc get secret api-server-tls -n openshift-config -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check APIServer configuration
oc get apiserver cluster -o yaml | grep -A 10 namedCertificates
```

### Verify TLS in Browser

```bash
# Test apps wildcard certificate (should show Let's Encrypt)
curl -v https://console-openshift-console.apps.<your-cluster-domain> 2>&1 | grep -E "(issuer|subject)"

# Test API server certificate
curl -v https://api.<your-cluster-domain>:6443 2>&1 | grep -E "(issuer|subject)"

# Or open in browser:
# https://console-openshift-console.apps.<your-cluster-domain>
# Should show valid Let's Encrypt certificate with no warnings
```

### Certificate Issuance Timeline

**Expected duration for certificate issuance:**
- cert-manager operator deployment: ~2-3 minutes
- OCI DNS webhook deployment: ~1 minute
- DNS-01 challenge completion: ~2-3 minutes
- Certificate issuance: ~1 minute
- **Total: ~6-8 minutes**

**Expected states after successful deployment:**
1. ClusterIssuer status: `Ready=True`
2. Certificate status: `Ready=True`
3. Browser: Shows "Secure" with Let's Encrypt certificate
4. No certificate warnings in OpenShift console

### Troubleshooting Certificate Issues

```bash
# Check cert-manager logs
oc logs -n cert-manager -l app=cert-manager

# Check certificate order status
oc get order -A

# Check ACME challenges
oc get challenge -A

# View challenge details (if stuck)
oc describe challenge -A

# Check DNS TXT records created by webhook
# Look for _acme-challenge.<domain> TXT records in OCI DNS console

# Force certificate renewal (if needed)
oc delete certificaterequest -n openshift-ingress --all
```


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


# GKE: cert-manager using Let’s Encrypt
The cert-manager project automatically provisions and renews TLS certificates in Kubernetes. It supports using your own 
certificate authority, self signed certificates, certificates managed by the Hashicorp Vault PKI, and of course the free 
certificates issued by Let’s Encrypt.


## Installing with Helm
**Note:** cert-manager should never be embedded as a sub-chart into other Helm charts. cert-manager manages non-namespaced 
resources in your cluster and should only be installed once.

### Prerequisites 
- Helm `v2` or `v3` installed
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) enabled for GKE

### Steps
In order to install the Helm chart, you must follow these steps:

Create the namespace for cert-manager:

```kubectl create namespace cert-manager```
    
Add the Jetstack Helm repository:

**Warning:** It is important that this repository is used to install cert-manager. The version residing in the helm 
stable repository is deprecated and should not be used.

```helm repo add jetstack https://charts.jetstack.io```

Update your local Helm chart repository cache:

```helm repo update```

To install the cert-manager Helm chart:

```
# Helm v3+
$ helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.16.0 \
  --set installCRDs=true
```

If there is a problem with havin split-horizon DNS, please use self-check DNS via

```
# Helm v3+
$ helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.16.1 \
  --set extraArgs='{--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}',installCRDs=true
```

## Verifying the installation
Once you’ve installed cert-manager, you can verify it is deployed correctly by checking the cert-manager namespace for running pods:

```
kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-5c6866597-zw7kh               1/1     Running   0          2m
cert-manager-cainjector-577f6d9fd7-tr77l   1/1     Running   0          2m
cert-manager-webhook-787858fcdb-nlzsq      1/1     Running   0          2m
```

## Issuing a certificate

### GKE Workload Identity
If you are deploying cert-manager into a Google Container Engine (GKE) cluster with workload identity enabled, you can 
leverage workload identity to avoid creating and managing static service account credentials. The [workload identity 
how-to](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) provides more detail on how workload 
identity functions, but briefly workload identity allows you to link a 
Google service accounts (GSA) to Kubernetes service accounts (KSA). This GSA/KSA linking is two-way, i.e., you must 
establish the link in GCP and Kubernetes. Once configured, workload identity allows Kubernetes pods running under a KSA 
to access the GCP APIs with the permissions of the linked GSA. The workload identity how-to also provides detailed 
instructions on how to enable workload identity in your GKE cluster. The instructions in the following sections assume 
you are deploying cert-manager to a GKE cluster with workload identity already enabled.

#### Google IAM Service Account Credentials API
Please enable this API on a project base.

`https://console.developers.google.com/apis/library/iamcredentials.googleapis.com?project=$PROJECT_NAME`

#### Create a Service Account Secret
cert-manager needs to be able to add records to CloudDNS in order to solve the DNS01 challenge. To enable this, a GCP 
service account must be created with the `dns.admin` role.

```
PROJECT_NAME=[YOUR_PROJECT_NAME]
gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"

$ gcloud projects add-iam-policy-binding $PROJECT_NAME \
   --member serviceAccount:dns01-solver@$PROJECT_NAME.iam.gserviceaccount.com \
   --role roles/dns.admin
```

#### Link KSA to GSA in GCP
The cert-manager component that needs to modify DNS records is the pod created as part of the cert-manager deployment. 
The standard methods for deploying cert-manger to Kubernetes create the cert-manager deployment in the cert-manager 
namespace and its pod spec specifies it runs under the cert-manager service account. To link the GSA you created above 
to the cert-manager KSA in the cert-manager namespace in your GKE cluster, run the following command.

```
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT_NAME.svc.id.goog[cert-manager/cert-manager]" \
    dns01-solver@$PROJECT_NAME.iam.gserviceaccount.com
```

If your cert-manager pods are running under a different service account, replace `goog[cert-manager/cert-manager]` with 
`goog[NAMESPACE/SERVICE_ACCOUNT]`, where `NAMESPACE` is the namespace of the service account and `SERVICE_ACCOUNT` is 
the name of the service account.

#### Link KSA to GSA in Kubernetes
After deploying cert-manager, add the proper workload identity annotation to the cert-manager service account.

```
kubectl annotate serviceaccount --namespace=cert-manager cert-manager \
    "iam.gke.io/gcp-service-account=dns01-solver@$PROJECT_NAME.iam.gserviceaccount.com"
```

Again, if your cert-manager pods are running under a different service account, replace `--namespace=cert-manager cert-manager`
with `--namespace=NAMESPACE SERVICE_ACCOUNT`, where `NAMESPACE` is the namespace of the service account and `SERVICE_ACCOUNT`
is the name of the service account.

If you are deploying cert-manager using its helm chart, you can use the `serviceAccount.annotations` configuration 
parameter to add the above workload identity annotation to the cert-manager KSA.

### Create ClusterIssuer  
Apply:

```kubectl apply -f clusterissuer-dev.yml```  

Validate:

```kubectl describe clusterissuer letsencrypt-issuer-dev```

### Certificate
Once we have created the above ClusterIssuer, we can use it to obtain a certificate.

To request a certificate from Let’s Encrypt (or any Certificate Authority), you need to provide some kind of proof that 
you are entitled to receive the certificate for a given domain. Let’s Encrypt support two methods of validation to prove 
control of your domain, http-01 (validation over HTTP) and dns-01 (validation via DNS). Wildcard domain certificates 
(those covering *.yourdomain.com) can only be requested using DNS validation.

cert-manager will periodically check its validity and attempt to renew it if it gets close to expiry. cert-manager 
considers certificates to be close to expiry when the ‘Not After’ field on the certificate is less than the current time 
plus 30 days.

```kubectl apply -f <ENV>/certificate-<...>.yml``` 

### Validate certificate creation

```
kubectl describe secret [YOUR CERTIFICATE]
kubectl describe cert [YOUR CERTIFICATE]
```

### Ingress w/ existing Certificate
*Note:* There is no need to include the annotations *cert-manager.io* section if you’ve already created a certificate.

```
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: istio-ingress
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.global-static-ip-name: istio-gateway-static-ip
    kubernetes.io/ingress.allow-http: "false"
spec:
  tls:
  # use an already existing certificate within the same namespace
  - secretName: services-usercentrics-sandbox-tls
    hosts:
    - '*.services.usercentrics-sandbox.eu'
  backend:
    serviceName: istio-ingressgateway
    servicePort: 80
```

### IMPORTANT! Root Certificate
The staging environment intermediate certificate (“Fake LE Intermediate X1”) is issued by a root certificate not present 
in browser/client trust stores. If you wish to modify a test-only client to trust the staging environment for testing 
purposes you can do so by adding the “Fake LE Root X1” certificate to your testing trust store. Important: Do not add 
the staging root or intermediate to a trust store that you use for ordinary browsing or other activities, since they are 
not audited or held to the same standards as our production roots, and so are not safe to use for anything other than testing.

## Uninstalling with Helm
Simple as life...

```helm uninstall cert-manager -n cert-manager```

Clean the leftovers, e.g. configuration

```kubectl delete ns cert-manager```
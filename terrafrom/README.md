# Terraform
An alternative to Ansible to automate provisioning and maintenance of GKE Clusters
## Install
[Download](https://www.terraform.io/downloads.html) and install Terraform on your local environment.
## Service Accounts
It is recommended to use a dedicated service account to work with GCP:

+ Manually: 

Go to [Cloud Console](https://console.cloud.google.com/) and navigate to **IAM & Admin** > **Service Accounts**, and 
click **Create Service Account**.
Name the service account `terraform and assign it the **Project Editor** role. Choose **Create Key** to create a private
 key in JSON format. Your browser will download a JSON file containing the details of the service account and a private 
key that can authenticate as a project editor to your project. *Keep this JSON file safe!* Anyone with access to 
this file can create billable resources in your project.

+ via CLI:
    
```bash
MY_ENV=[stage|prod]
SERVICE_ACCOUNT_NAME=terraform-gcp-sa
SERVICE_ACCOUNT_DEST=~/.gcp/gcp-sa-${MY_ENV}.json

gcloud iam service-accounts create \
    ${SERVICE_ACCOUNT_NAME} \
    --display-name ${SERVICE_ACCOUNT_NAME}

SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:${SERVICE_ACCOUNT_NAME}" \
    --format='value(email)')

PROJECT_ID=$(gcloud info --format='value(config.project)')

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --role roles/editor --member serviceAccount:${SA_EMAIL}

mkdir -p $(dirname ${SERVICE_ACCOUNT_DEST})

gcloud iam service-accounts keys create ${SERVICE_ACCOUNT_DEST} \
    --iam-account ${SA_EMAIL}
```

## Remote Terraform State
Next create a GCS Bucket that will be used to hold Terraform state information. Using remote Terraform state makes it 
easier to collaborate on Terraform projects. The storage bucket name must be globally unique, the suggested name is 
`{PROJECT_ID}-terraform-state`. After creating the bucket update the IAM permissions to make the `terraform` service account
 an `objectAdmin`.
 
```bash
REGION="europe-west1"
BUCKET_NAME="${PROJECT_ID}-terraform-state"
gsutil mb -l ${REGION} gs://${BUCKET_NAME}
gsutil iam ch serviceAccount:${SA_EMAIL}:objectAdmin gs://${BUCKET_NAME}
```

## APIs
Each major product group in GCP has its own API, so one more quick thing we need to do is enable the Kubernetes API for 
our project before Terraform can talk to it.

From the Cloud Console, navigate to **APIs & Services > Dashboard**, then click **Enable APIs and Services**. 
Type 'kubernetes' in the search box, and you should find the Kubernetes Engine API. Then just click **Enable** (if you 
see a button that says “Manage”, then the API is already enabled). APIs can take a few minutes to enable fully, so fetch
 yourself a hot beverage at this point. 

## Providers
The first thing we need to declare is a provider. Terraform can interact with the APIs of all the major cloud providers,
 plus several PaaS offerings and other applications. This is achieved through providers. So to create resources in GCP 
we need to declare that we’re using the google provider. Please take a look at `main.tf` file in your directory.
Now you could run `terraform init` to initialize your local environment.

## Resources
Once the provider is in place we can declare resources for Terraform to deploy. Resources are simply the pieces of 
infrastructure we want to create: compute instances, disks, storage buckets and so on. Declaring resources will form the
 bulk of most infrastructure code.
 
## Plan & Apply
Run the following command to see what changes will be applied on the target
`terraform plan`. After careful consideration of future changes, please run 
`terraform apply` to apply changes.

## Separation on ENVs
+ 
    `terraform init -backend-config=environments/${MY_ENV}/backend.config .`
    
    *Output:*
    
```bash 
Initializing modules...
- gke_cluster in modules/gke-cluster
- node_pools in modules/pools
- vpc_network in modules/vpc-network
- vpc_network.network_firewall in modules/network-firewall

Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "google" (hashicorp/google) 3.28.0...
- Downloading plugin for provider "google-beta" (terraform-providers/google-beta) 3.28.0...
- Downloading plugin for provider "random" (hashicorp/random) 2.2.1...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.random: version = "~> 2.2"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary. 
```
    
+ 
    `terraform plan -var-file=environments/${MY_ENV}/variables.tfvars --out /tmp/${MY_ENV}.plan`
    
    *Output:*
        
```bash
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.gke_cluster.data.google_compute_zones.available: Refreshing state...
module.gke_cluster.data.google_container_engine_versions.location: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:
...
[ list of actions here ]  
...

Plan: 14 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: /tmp/stage.plan

To perform exactly these actions, run the following command to apply:
terraform apply "/tmp/stage.plan"
```
    
+ 
    `terraform apply /tmp/${MY_ENV}.plan`
    
    *Output:*
     
```bash
random_string.suffix: Creating...
random_string.suffix: Creation complete after 0s [id=0a73]
module.gke_cluster.random_shuffle.available_zones: Creating...
module.vpc_network.google_compute_network.vpc: Creating...
...
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

client_certificate =
client_key = <sensitive>
cluster_ca_certificate = <sensitive>
cluster_endpoint = <sensitive>
```
        
+ 
    `terrafrom destroy -var-file=environments/${MY_ENV}/variables.tfvars`

## Workload Identity 
After applying workload identity on a cluster you have to take care about following SA(service account) bindings:

```
PROJECT_NAME=[YOUR_PROJECT_NAME]

gcloud iam service-accounts create istio-grafana-sd-adapter --project "$PROJECT_NAME" --display-name "Monitoring SA"

gcloud projects add-iam-policy-binding $PROJECT_NAME \                      
   --member serviceAccount:istio-grafana-sd-adapter@$PROJECT_NAME.iam.gserviceaccount.com \
   --role roles/monitoring.editor

gcloud projects add-iam-policy-binding $PROJECT_NAME \                      
   --member serviceAccount:istio-grafana-sd-adapter@$PROJECT_NAME.iam.gserviceaccount.com \
   --role roles/logging.logWriter

gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT_NAME.svc.id.goog[NAMESPACE/default]" \
    istio-grafana-sd-adapter@$PROJECT_NAME.iam.gserviceaccount.com

kubectl annotate serviceaccount --namespace=NAMESPACE default \ 
    "iam.gke.io/gcp-service-account=istio-grafana-sd-adapter@$PROJECT_NAME.iam.gserviceaccount.com"

### do rollout restart of existing 
kubectl rollout restart deployment APP_NAME -n NAMESPACE
```

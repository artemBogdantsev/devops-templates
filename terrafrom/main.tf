# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# This is an example of how to use the gke-cluster module to deploy a public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"
  backend "gcs" {}
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  version = ">= 3.16.0"
  region      = var.region
  project     = var.project
  credentials = file(var.account_file_path)
}

provider "google-beta" {
  version = ">= 3.16.0"
  region      = var.region
  project     = var.project
  credentials = file(var.account_file_path)
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
  source = "./modules/vpc-network"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block

  # more granular IP spacing
  cidr_subnetwork_width_delta           = var.vpc_cidr_subnetwork_width_delta
  cidr_subnetwork_spacing               = var.vpc_cidr_subnetwork_spacing
  secondary_cidr_subnetwork_width_delta = var.vpc_secondary_cidr_subnetwork_width_delta
  secondary_cidr_subnetwork_spacing     = var.vpc_secondary_cidr_subnetwork_spacing

}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------
module "gke_cluster" {
  source = "./modules/gke-cluster"

  name        = var.cluster_name
  project     = var.project
  regional    = var.regional
  region      = var.region
  zones       = var.zones
  description = var.description
  istio       = var.istio
  cloudrun       = var.cloudrun
  default_max_pods_per_node = var.default_max_pods_per_node
  kubernetes_version = var.kubernetes_version


  # Node Auto Provisioning
  cluster_autoscaling = var.cluster_autoscaling

  # We're deploying the cluster in the 'public' subnetwork to allow outbound internet access
  # See the network access tier table for full details:
  # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
  network = module.vpc_network.network

  subnetwork                   = module.vpc_network.public_subnetwork
  cluster_secondary_range_name = module.vpc_network.public_subnetwork_pods_secondary_range_name
  services_secondary_range_name = module.vpc_network.public_subnetwork_services_secondary_range_name

  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling

  # Securing secrets with KMS encription on a disk. Use it on your own RISK!
  # secrets_encryption_kms_key = var.secrets_encryption_kms_key
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------
module "node_pools" {
  source = "./modules/pools"

  cluster_name      = module.gke_cluster.name
  location          = module.gke_cluster.location
  node_pools        = var.node_pools
  node_pools_labels = var.node_pools_labels
  node_pools_taints = var.node_pools_taints
  max_pods_per_node = module.gke_cluster.max_pods_per_node
}


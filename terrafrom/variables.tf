# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
	description = "The project ID where all resources will be launched"
	type        = string
}

variable "regional" {
	type        = bool
	description = "Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!)"
}

variable "region" {
	type        = string
	description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
}

variable "cluster_name" {
	description = "The name of the Kubernetes cluster"
	type        = string
}

variable "account_file_path" {
	description = "Default location of the auth file for the Service Account used for the GKE cluster"
	type 		= string
}

variable "kubernetes_version" {
	description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region"
	type        = string
	default     = "latest"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "zones" {
	type        = list(string)
	description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
	default     = []
}

variable "node_pools" {
	type        = list(map(string))
	description = "List of maps containing node pools"

	default = [
		{
			name = "default-node-pool"
		},
	]
}

variable "node_pools_labels" {
	type        = map(map(string))
	description = "Map of maps containing node labels by node-pool name"

	# Default is being set in variables_defaults.tf
	default = {
		all               = {}
		default-node-pool = {}
	}
}

variable "node_pools_taints" {
	type        = map(list(object({ key = string, value = string, effect = string })))
	description = "Map of lists containing node taints by node-pool name"

	# Default is being set in variables_defaults.tf
	default = {
		all               = []
		default-node-pool = []
	}
}

variable "description" {
	description = "The description of the cluster"
	type        = string
	default     = "Example Cluster"
}

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
	description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27"
	type        = string
	default     = "10.3.0.0/16"
}

# For the example, we recommend a /16 network for the secondary range. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_secondary_cidr_block" {
	description = "The IP address range of the VPC's secondary address range in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27"
	type        = string
	default     = "10.4.0.0/16"
}

variable "enable_vertical_pod_autoscaling" {
	description = "Enable vertical pod autoscaling"
	type        = string
	default     = false
}

variable "secrets_encryption_kms_key" {
	description = "The Cloud KMS key to use for the encryption of secrets in etcd, e.g: projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
	type        = string
	default     = null
}

variable "istio" {
	description = "Boolean to enable / disable Istio"
	default     = true
}

variable "cluster_autoscaling" {
	type = object({
		enabled             = bool
		autoscaling_profile = string
		min_cpu_cores       = number
		max_cpu_cores       = number
		min_memory_gb       = number
		max_memory_gb       = number
	})
	default = {
		enabled             = false
		autoscaling_profile = "BALANCED"
		max_cpu_cores       = 0
		min_cpu_cores       = 0
		max_memory_gb       = 0
		min_memory_gb       = 0
	}
	description = "Cluster autoscaling configuration. See [more details](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#clusterautoscaling)"
}
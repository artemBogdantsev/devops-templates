# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "name" {
  description = "The name of the cluster"
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

variable "network" {
  description = "A reference (self link) to the VPC network to host the cluster in"
  type        = string
}

variable "subnetwork" {
  description = "A reference (self link) to the subnetwork to host the cluster in"
  type        = string
}

variable "cluster_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the cluster to use"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------
variable "description" {
  description = "The description of the cluster"
  type        = string
  default     = ""
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
  default     = []
}

variable "release_channel" {
  type 		= string
  default 	= "REGULAR"

  description = <<EOF
Kubernetes releases updates often, to deliver security updates, fix known
issues, and introduce new features. Release channels provide control over how
often clusters are automatically updated , and offer customers the ability to
balance between stability and functionality of the version deployed in the
cluster.

When you enroll a new cluster in a release channel, Google automatically
manages the version and upgrade cadence for the cluster and its node pools. All
channels offer supported releases of GKE and are considered GA (although
individual features may not always be GA, as marked). The Kubernetes releases
in these channels are official Kubernetes releases and include both GA and beta
Kubernetes APIs (as marked). New Kubernetes versions are first released to the
Rapid channel, and over time will be promoted to the Regular, and Stable
channel. This allows you to subscribe your cluster to a channel that meets your
business, stability, and functionality needs.
EOF
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region"
  type        = string
  default     = "latest"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com/kubernetes, logging.googleapis.com (legacy), and none"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Stackdriver Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting. Available options include monitoring.googleapis.com/kubernetes, monitoring.googleapis.com (legacy), and none"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Control whether nodes have internal IP addresses only. If enabled, all nodes are given only RFC 1918 private addresses and communicate with the master via private networking"
  type        = bool
  default     = false
}

variable "disable_public_endpoint" {
  description = "Control whether the master's internal IP address is used as the cluster endpoint. If set to 'true', the master can only be accessed from internal IP addresses"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network. This range will be used for assigning internal IP addresses to the master or set of masters, as well as the ILB VIP. This range must not overlap with any other ranges in use within the cluster's network"
  type        = string
  default     = ""
}

variable "network_project" {
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  type        = string
  default     = ""
}

variable "master_authorized_networks_config" {
  description = <<EOF
  The desired configuration options for master authorized networks. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)
  ### example format ###
  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "10.0.0.0/8"
      display_name = "example_network"
    }],
  }]
EOF
  type        = list(any)
  default     = []
}

#variable "maintenance_start_time" {
#  description = "Time window specified for daily maintenance operations in RFC3339 format"
#  type        = string
#  default     = "05:00"
#}

variable "stub_domains" {
  description = "Map of stub domains and their resolvers to forward DNS queries for a certain domain to an external DNS server"
  type        = map(string)
  default     = {}
}

variable "non_masquerade_cidrs" {
  description = "List of strings in CIDR notation that specify the IP address ranges that do not use IP masquerading"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "ip_masq_resync_interval" {
  description = "The interval at which the agent attempts to sync its ConfigMap file from the disk"
  type        = string
  default     = "60s"
}

variable "ip_masq_link_local" {
  description = "Whether to masquerade traffic to the link-local prefix (169.254.0.0/16)"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS - RECOMMENDED DEFAULTS
# These values shouldn't be changed; they're following the best practices defined at https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_legacy_abac" {
  description = "Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC"
  type        = bool
  default     = false
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master, which is required to be enabled to be used on Nodes"
  type        = bool
  default     = true
}

variable "basic_auth_username" {
  description = "The username used for basic auth; set both this and `basic_auth_password` to \"\" to disable basic auth"
  type        = string
  default     = ""
}

variable "basic_auth_password" {
  description = "The password used for basic auth; set both this and `basic_auth_username` to \"\" to disable basic auth"
  type        = string
  default     = ""
}

variable "enable_client_certificate_authentication" {
  description = "Whether to enable authentication by x509 certificates. With ABAC disabled, these certificates are effectively useless"
  type        = bool
  default     = false
}

# See https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control#google-groups-for-gke
variable "gsuite_domain_name" {
  description = "The domain name for use with Google security groups in Kubernetes RBAC. If a value is provided, the cluster will be initialized with security group `gke-security-groups@[yourdomain.com]`"
  type        = string
  default     = null
}

variable "secrets_encryption_kms_key" {
  description = "The Cloud KMS key to use for the encryption of secrets in etcd, e.g: projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
  type        = string
  default     = null
}

# See https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler
variable "enable_vertical_pod_autoscaling" {
  description = "Whether to enable Vertical Pod Autoscaling"
  type        = string
  default     = false
}

variable "services_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the services to use"
  type        = string
  default     = null
}

variable "istio" {
  description = "(Beta) Enable Istio addon"
  default     = false
}

variable "istio_auth" {
  type        = string
  description = "(Beta) The authentication type between services in Istio."
  default     = "AUTH_NONE" #AUTH_NONE: permissive, AUTH_MUTUAL_TLS: for strict
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

variable "identity_namespace" {
  description = "Workload Identity namespace. (Default value of `enabled` automatically sets project based namespace `[project_id].svc.id.goog`)"
  type        = string
  default     = "enabled"
}

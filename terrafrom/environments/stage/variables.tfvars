project            = "usercentrics-staging"
cluster_name       = "usercentrics-staging"
region             = "europe-west1"
regional           = true
account_file_path  = "~/.gcp/gcp-sa-stage.json"
kubernetes_version = "1.18.16-gke.302"
istio              = true # make sure you enable it with init install
enable_vertical_pod_autoscaling = true

vpc_cidr_block           = "10.64.0.0/10"
vpc_secondary_cidr_block = "10.128.0.0/10"

# Optional
description = "A K8s cluster for Staging workflows. V2"
default_max_pods_per_node = "32"

cluster_autoscaling = {
  enabled             = true
  autoscaling_profile = "BALANCED"
  max_cpu_cores       = 256
  min_cpu_cores       = 12
  max_memory_gb       = 1024
  min_memory_gb       = 24
}

node_pools = [
  {
    name                       = "default"
    node_count                 = 2
    autoscaling                = false
    node_config_machine_type   = "e2-medium" # 2vCPU/4GB
  },
]
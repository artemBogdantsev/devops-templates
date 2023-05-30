project           = "staticfilesserver"
cluster_name      = "<YOUR_DOMAIN>-production"
region            = "europe-west1"
regional          = true
account_file_path = "~/.gcp/gcp-sa-prod.json"
kubernetes_version = "1.18.16-gke.2100"
istio             = true # make sure you enable it with init install
enable_vertical_pod_autoscaling = true

# it gives us from /11 to /14 2096K IP addresses and 8 subnets 256K each.
# from 10.0.0.0 to 10.32.255.254
vpc_cidr_block           = "10.0.0.0/11"
vpc_secondary_cidr_block = "10.0.0.0/11"

vpc_cidr_subnetwork_width_delta = 3
vpc_cidr_subnetwork_spacing = 2
vpc_secondary_cidr_subnetwork_width_delta = 3
vpc_secondary_cidr_subnetwork_spacing = 3

# Optional
description = "A K8s cluster for Production workflows"
default_max_pods_per_node = "32"

cluster_autoscaling = {
  enabled             = true
  autoscaling_profile = "BALANCED"
  max_cpu_cores       = 256
  min_cpu_cores       = 12
  max_memory_gb       = 2048
  min_memory_gb       = 24
}

node_pools = [
  {
    name                       = "default"
    autoscaling_min_node_count = 2
    autoscaling_max_node_count = 4
    node_config_machine_type   = "e2-medium" # 2vCPU/4GB
  },
]
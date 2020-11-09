project           = "staticfilesserver"
cluster_name      = "usercentrics-production"
region            = "europe-west1"
regional          = true
account_file_path = "~/.gcp/gcp-sa-prod.json"
kubernetes_version = "1.17.9-gke.1504"
istio             = false # make sure you enable it with init install

# Optional
description = "A K8s cluster for Production workflows"

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
    node_count                 = 3
    autoscaling                = false
    node_config_machine_type   = "e2-medium" # 2vCPU/4GB
  },
]
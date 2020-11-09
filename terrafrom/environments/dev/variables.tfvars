project           = "usercentrics-playground"
cluster_name      = "usercentrics-development"
region            = "europe-west1"
regional          = false
zones             = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
account_file_path = "~/.gcp/gcp-sa-stage.json" # use the same SA for TF

# Optional
description = "A K8s cluster for Development workflows. PLEASE DELETE IF NOT USING!!!"

cluster_autoscaling = {
  enabled             = true
  autoscaling_profile = "BALANCED"
  max_cpu_cores       = 96
  min_cpu_cores       = 12
  max_memory_gb       = 512
  min_memory_gb       = 12
}

node_pools = [
  {
    name                     = "default" # to keep system pods
    node_count               = 2         # is needed when autoscaling is off. 2 to have enough nodes for Istio
    autoscaling              = false
    node_config_machine_type = "e2-small" # 2vCPU/2GB
  },
]
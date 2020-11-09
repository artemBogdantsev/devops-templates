project           = "usercentrics-playground"
cluster_name      = "usercentrics-staging"
region            = "europe-west1"
regional          = false
zones             = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
account_file_path = "~/.gcp/gcp-sa-stage.json"

# Optional
description = "A K8s cluster for Development/Staging workflows"

node_pools = [
  {
    name                     = "default" # to keep system pods
    node_count               = 1
    autoscaling              = false
    node_config_machine_type = "e2-small"
  },
  {
    name                       = "standard"
    autoscaling_min_node_count = 0
    autoscaling_max_node_count = 3
    node_config_machine_type   = "e2-medium"
  },
  {
    name                       = "compute"
    autoscaling_min_node_count = 0
    autoscaling_max_node_count = 6
    node_config_machine_type   = "c2-standard-4"
  },
]

node_pools_labels = {
  all = {
    nodetype = "default"
  }
  compute = {
    nodetype = "compute"
  }
}

node_pools_taints = {
  all = [

  ]
  compute = [
    {
      key    = "reserved-pool"
      value  = true
      effect = "NO_SCHEDULE"
    },
  ]
}

secrets_encryption_kms_key = "projects/usercentrics-playground/locations/europe/keyRings/usercentrics-master-key/cryptoKeys/usercentrics-master-key"
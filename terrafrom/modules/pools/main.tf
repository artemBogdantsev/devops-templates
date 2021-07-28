locals {
  // Build a map of maps of node pools from a list of objects
  node_pool_names = [for np in toset(var.node_pools) : np.name]
  node_pools      = zipmap(local.node_pool_names, tolist(toset(var.node_pools)))

  // for workload identity
  cluster_node_metadata_config = var.node_metadata == "UNSPECIFIED" ? [] : [{
    node_metadata = var.node_metadata
  }]
}

# https://www.terraform.io/docs/providers/google/r/container_node_pool.html
resource "google_container_node_pool" "node_pool" {
  provider = google-beta
  for_each = local.node_pools
  location = var.location

  max_pods_per_node = var.max_pods_per_node

  # The name of the node pool. Instance groups created will have the cluster
  # name prefixed automatically.
  name = format("%s-pool", each.key)

  # The cluster to create the node pool for.
  cluster = var.cluster_name

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "initial_node_count",
    lookup(each.value, "autoscaling_min_node_count", 1)
  ) : null

  # with autoscaling this is not needed
  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  # Configuration required by cluster autoscaler to adjust the size of the node pool to the current cluster usage.
  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count = lookup(autoscaling.value, "autoscaling_min_node_count", 1)
      max_node_count = lookup(autoscaling.value, "autoscaling_max_node_count", 100)
    }
  }

  # Target a specific version
  version = lookup(each.value, "version", "")

  # Node management configuration, wherein auto-repair and auto-upgrade is configured.
  management {
    # Whether the nodes will be automatically repaired.
    auto_repair = lookup(each.value, "auto_repair", true)

    # Whether the nodes will be automatically upgraded. Master in zonal cluster will have a downtime
    auto_upgrade = lookup(each.value, "auto_upgrade", true)
  }

  upgrade_settings {
    max_surge       = lookup(each.value, "max_surge", 1)
    max_unavailable = lookup(each.value, "max_unavailable", 0)
  }

  # Parameters used in creating the cluster's nodes.
  node_config {
    image_type   = lookup(each.value, "node_config_image_type", "COS")
    machine_type = lookup(each.value, "node_config_machine_type", "e2-small")

    labels = merge(
      lookup(lookup(local.node_pools_labels, "default_values", {}), "cluster_name", true) ? { "cluster_name" = var.cluster_name } : {},
      lookup(lookup(local.node_pools_labels, "default_values", {}), "node_pool", true) ? { "node_pool" = each.value["name"] } : {},
      local.node_pools_labels["all"],
      local.node_pools_labels[each.value["name"]],
    )

    dynamic "taint" {
      for_each = concat(
        local.node_pools_taints["all"],
        local.node_pools_taints[each.value["name"]],
      )
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    # Size of the disk attached to each node, specified in GB. The smallest
    # allowed disk size is 10GB. Defaults to 100GB.
    disk_size_gb = lookup(each.value, "node_config_disk_size_gb", 100)

    # Type of the disk attached to each node (e.g. 'pd-standard' or 'pd-ssd').
    # If unspecified, the default disk type is 'pd-standard'
    disk_type = lookup(each.value, "node_config_disk_type", "pd-standard")

    # A boolean that represents whether or not the underlying node VMs are
    # preemptible. See the official documentation for more information.
    # Defaults to false.
    preemptible = lookup(each.value, "node_config_preemptible", false)

    # The set of Google API scopes to be made available on all of the node VMs
    # under the "default" service account. These can be either FQDNs, or scope
    # aliases. The cloud-platform access scope authorizes access to all Cloud
    # Platform services, and then limit the access by granting IAM roles
    # https://cloud.google.com/compute/docs/access/service-accounts#service_account_permissions
    oauth_scopes = concat(
      local.node_pools_oauth_scopes["all"],
      local.node_pools_oauth_scopes[each.value["name"]],
    )

    # The metadata key/value pairs assigned to instances in the cluster.
    metadata = {
      # https://cloud.google.com/kubernetes-engine/docs/how-to/protecting-cluster-metadata
      disable-legacy-endpoints = "true"
    }

    // for workload identity
    dynamic "workload_metadata_config" {
      for_each = local.cluster_node_metadata_config

      content {
        node_metadata = lookup(each.value, "node_metadata", workload_metadata_config.value.node_metadata)
      }
    }
  }

  # Change how long update operations on the node pool are allowed to take
  # before being considered to have failed. The default is 10 mins.
  # https://www.terraform.io/docs/configuration/resources.html#operation-timeouts
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
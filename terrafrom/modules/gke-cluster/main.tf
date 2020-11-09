# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A GKE CLUSTER
# This module deploys a GKE cluster, a managed, production-ready environment for deploying containerized applications.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# Get available zones in region
# ---------------------------------------------------------------------------------------------------------------------
data "google_compute_zones" "available" {
  provider = google-beta

  project = var.project
  region  = local.region
}

resource "random_shuffle" "available_zones" {
  input        = data.google_compute_zones.available.names
  result_count = 3
}

# ---------------------------------------------------------------------------------------------------------------------
# Prepare locals to keep the code cleaner
# ---------------------------------------------------------------------------------------------------------------------
locals {
  // location
  zone_count = length(var.zones)
  location   = var.regional ? var.region : var.zones[0]
  region     = var.regional ? var.region : join("-", slice(split("-", var.zones[0]), 0, 2))
  // for regional cluster - use var.zones if provided, use available otherwise, for zonal cluster use var.zones with first element extracted
  node_locations = var.regional ? coalescelist(compact(var.zones), sort(random_shuffle.available_zones.result)) : slice(var.zones, 1, length(var.zones))

  // versions
  release_channel    = var.release_channel == "" ? [] : [var.release_channel]
  latest_version     = data.google_container_engine_versions.location.latest_master_version
  kubernetes_version = var.kubernetes_version != "latest" ? var.kubernetes_version : local.latest_version
  network_project    = var.network_project != "" ? var.network_project : var.project

  // node auto provisioning
  autoscaling_resource_limits = var.cluster_autoscaling.enabled ? [{
    resource_type = "cpu"
    minimum       = var.cluster_autoscaling.min_cpu_cores
    maximum       = var.cluster_autoscaling.max_cpu_cores
  }, {
    resource_type = "memory"
    minimum       = var.cluster_autoscaling.min_memory_gb
    maximum       = var.cluster_autoscaling.max_memory_gb
  }] : []

  // workload identity enabled
  workload_identity_enabled = ! (var.identity_namespace == null || var.identity_namespace == "null")
  cluster_workload_identity_config = ! local.workload_identity_enabled ? [] : var.identity_namespace == "enabled" ? [{
    identity_namespace = "${var.project}.svc.id.goog" }] : [{ identity_namespace = var.identity_namespace
  }]
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the GKE Cluster
# We want to make a cluster with no node pools, and manage them all with the fine-grained google_container_node_pool resource
# ---------------------------------------------------------------------------------------------------------------------
# https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "cluster" {
  provider = google-beta # because we use some BETA e.g. release channel or autoscaling profile

  name              = var.name
  description       = var.description
  project           = var.project

  location          = local.location
  node_locations    = local.node_locations

  network    = var.network
  subnetwork = var.subnetwork

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
  min_master_version = local.kubernetes_version

  dynamic "release_channel" {
    for_each = toset(local.release_channel)

    content {
      channel = release_channel.value
    }
  }

  # Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC.
  enable_legacy_abac = var.enable_legacy_abac

  # The API requires a node pool or an initial count to be defined; that initial count creates the
  # "default node pool" with that # of nodes.
  # So, we need to set an initial_node_count of 1. This will make a default node
  # pool with server-defined defaults that Terraform will immediately delete as
  # part of Create. This leaves us in our desired state- with a cluster master
  # with no node pools.
  remove_default_node_pool = true
  initial_node_count = 1

  # ip_allocation_policy.use_ip_aliases defaults to true, since we define the block `ip_allocation_policy`
  ip_allocation_policy {
    // Choose the range, but let GCP pick the IPs within the range
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name != null ? var.services_secondary_range_name : var.cluster_secondary_range_name
  }

  # We can optionally control access to the cluster
  # See https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
  private_cluster_config {
    enable_private_endpoint = var.disable_public_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  addons_config {
    http_load_balancing {
      disabled = ! var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = ! var.horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = ! var.enable_network_policy
    }

    istio_config {
      disabled = ! var.istio
      auth     = var.istio_auth
    }
  }

  network_policy {
    enabled = var.enable_network_policy

    # Tigera (Calico Felix) is the only provider
    provider = "CALICO"
  }

  cluster_autoscaling {
    enabled             = var.cluster_autoscaling.enabled
    autoscaling_profile = var.cluster_autoscaling.autoscaling_profile != null ? var.cluster_autoscaling.autoscaling_profile : "BALANCED"
    dynamic "resource_limits" {
      for_each = local.autoscaling_resource_limits
      content {
        resource_type = lookup(resource_limits.value, "resource_type")
        minimum       = lookup(resource_limits.value, "minimum")
        maximum       = lookup(resource_limits.value, "maximum")
      }
    }
  }

  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  master_auth {
    username = var.basic_auth_username
    password = var.basic_auth_password
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = lookup(master_authorized_networks_config.value, "cidr_blocks", [])
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = lookup(cidr_blocks.value, "display_name", null)
        }
      }
    }
  }

#  maintenance_policy {
#    daily_maintenance_window {
#      start_time = var.maintenance_start_time
#    }
#  }

  lifecycle {
    ignore_changes = [
      # Since we provide `remove_default_node_pool = true`, the `node_config` is only relevant for a valid construction of
      # the GKE cluster in the initial creation. As such, any changes to the `node_config` should be ignored.
      node_config,
    ]
  }

  # If var.gsuite_domain_name is non-empty, initialize the cluster with a G Suite security group
  dynamic "authenticator_groups_config" {
    for_each = [
      for x in [var.gsuite_domain_name] : x if var.gsuite_domain_name != null
    ]

    content {
      security_group = "gke-security-groups@${authenticator_groups_config.value}"
    }
  }

  # If var.secrets_encryption_kms_key is non-empty, create ´database_encryption´ -block to encrypt secrets at rest in etcd
  dynamic "database_encryption" {
    for_each = [
      for x in [var.secrets_encryption_kms_key] : x if var.secrets_encryption_kms_key != null
    ]

    content {
      state    = "ENCRYPTED"
      key_name = database_encryption.value
    }
  }

  dynamic "workload_identity_config" {
    for_each = local.cluster_workload_identity_config

    content {
      identity_namespace = workload_identity_config.value.identity_namespace
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Pull in data
# ---------------------------------------------------------------------------------------------------------------------

// Get available master versions in our location to determine the latest version
data "google_container_engine_versions" "location" {
  location = local.zone_count == 0 ? data.google_compute_zones.available.names[0] : var.zones[0]
  project  = var.project
}

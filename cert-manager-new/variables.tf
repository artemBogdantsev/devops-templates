variable "automation" {
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
    prefix         = string
    bootstrap = object({
      repo         = string
      project_name = string
      folder_name  = string
      folder_id    = string
      pid          = string
      sa           = string
      wif          = string
      cost_element = string
      location     = string
      kms_key      = string
    })
    projects = map(object({
      repos            = list(string)
      descriptive_name = string
      pid              = string
      sa               = string
      wif              = string
      service_agents   = map(object({}))
    }))
    billing_account = object({
      id = string
    })
    federated_identity_pool = string
    federated_identity_provider = map(object({
      issuer           = string
      issuer_uri       = string
      name             = string
      principalset_tpl = string
    }))
  })

  validation {
    condition = alltrue([
      (var.automation.bootstrap.kms_key != null && var.automation.bootstrap.kms_key != "") &&
      (var.automation.bootstrap.location != null && var.automation.bootstrap.location == "europe-west3")
    ])
    error_message = "For Sovereign Controls please make sure KMS key is provided as well as right region is set"
  }
}

# Required variables
variable "create_namespace" {
  description = "Whether or not to create a namespace. Disable this if providing an already existing namespace."
  type        = bool
}

variable "namespace" {
  description = "The namespace name to use for all resources. If providing an already existing namespace, set this variable and also disable create_namespace"
  type        = string
}

variable "helm_release_name" {
  description = "The name of the Helm release"
  type        = string
}

variable "chart_path" {
  description = "The path to the helm chart used to apply the eck operator"
  type        = string
}

variable "chart_version" {
  description = "The eck operator chart version"
  type        = string
}

variable "image_registry" {
  description = "The name of the image. Used in the following format: <image_registry>/<image_name>"
  type        = string
}

variable "image_repository" {
  description = "The name of the image. Used in the following format: <image_name>"
  type        = string
}

variable "image_tag" {
  description = "The tag of the image"
  type        = string
}

variable "image_pull_policy" {
  description = "The Kubernetes image pull policy used by all workloads"
  type        = string
  default     = "IfNotPresent"
}

variable "ode_sov_network" {
  type = object({
    on_prem_subnet_id = string
    proxy_vip         = string
    subnet_id         = string
    vpc_id            = string
  })

  description = "ODE SOV Shared VPC Info"
}

variable "tpam_conjur" {
  type = map(string)
  description = "A map of T-PAM available secrets"
  default = null
}

variable "gcp_sa_account" {
  default = "GCP SA account used to access GCS buckets"
  type    = string
}
data "conjur_secret" "ode_sov_tls_key" {
  name = var.tpam_conjur.ode_sov_tls_key
}

data "conjur_secret" "ode_sov_tls_crt" {
  name = var.tpam_conjur.ode_sov_tls_crt
}

resource "kubernetes_namespace" "client_namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "cert_manager_helm" {
  name    = var.helm_release_name
  chart   = var.chart_path
  version = var.chart_version

  namespace = var.namespace
  values = [templatefile("${path.module}/templates/helm-vars.yml.tpl", {
    "image_repository"  = var.image_repository
    "image_registry"    = var.image_registry
    "image_pull_policy" = var.image_pull_policy
    "image_tag"         = var.image_tag
    "namespace"         = var.namespace
    "ode_sov_proxy_vip" = var.ode_sov_network.proxy_vip
    "gcp_sa_account"    = var.gcp_sa_account
  })]

  depends_on = [
    kubernetes_namespace.client_namespace
  ]
}

resource "kubectl_manifest" "cert_manager_issuer" {
  yaml_body = templatefile("self-signed/issuer.yml.tpl", {})
  depends_on = [
    helm_release.cert_manager_helm
  ]
}

data "kubectl_path_documents" "docs" {
  pattern = "./self-signed/manifests/*.yml"
}

resource "kubectl_manifest" "cert_manager_confluent_certs" {
  for_each  = data.kubectl_path_documents.docs.manifests
  yaml_body = each.value
  depends_on = [
    kubectl_manifest.cert_manager_issuer
  ]
}

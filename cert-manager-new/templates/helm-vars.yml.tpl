serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: ${gcp_sa_account}
image:
  repository: ${image_registry}/${image_repository}
  tag: ${image_tag}
  pullPolicy: ${image_pull_policy}
crds:
  enabled: true
http_proxy: "http://${ode_sov_proxy_vip}:3128"
https_proxy: "http://${ode_sov_proxy_vip}:3128"
webhook:
  image:
    repository: ${image_registry}/quay.io/jetstack/cert-manager-webhook
    tag: ${image_tag}
    pullPolicy: ${image_pull_policy}
cainjector:
  image:
    repository: ${image_registry}/quay.io/jetstack/cert-manager-cainjector
    tag: ${image_tag}
    pullPolicy: ${image_pull_policy}
acmesolver:
  image:
    repository: ${image_registry}/quay.io/jetstack/cert-manager-acmesolver
    tag: ${image_tag}
    pullPolicy: ${image_pull_policy}
startupapicheck:
  image:
    repository: ${image_registry}/quay.io/jetstack/cert-manager-startupapicheck
    tag: ${image_tag}
    pullPolicy: ${image_pull_policy}
global:
  leaderElection:
    namespace: cert-manager
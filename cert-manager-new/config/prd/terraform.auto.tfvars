create_namespace  = true
namespace         = "cert-manager"
helm_release_name = "cert-manager"
chart_path        = "oci://europe-west3-docker.pkg.dev/de0360-ode-sov-il-prd0/sov-rubix-helm-repo/cert-manager/cert-manager"
chart_version     = "v1.17.1"
image_registry    = "europe-west3-docker.pkg.dev/de0360-ode-sov-il-prd0/sov-rubix-docker-repo"
image_repository  = "quay.io/jetstack/cert-manager-controller"
image_tag         = "v1.17.1"
gcp_sa_account    = "svc-il-0@de0360-ode-sov-il-prd0.iam.gserviceaccount.com"

tpam_conjur = {
  ode_sov_tls_key = "spm/v1/20888/odesovdev/ODE_SOV_PRD_PKI"
  ode_sov_tls_crt = "spm/v1/20888/odesovdev/ODE_SOV_PRD_PEM"
}
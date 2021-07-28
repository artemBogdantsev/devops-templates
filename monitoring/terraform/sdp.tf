# Smart Data Protector Services
# 1. GKE - Privacy Proxy API
data "google_monitoring_cluster_istio_service" "privacy-proxy-svc" {
  location = "europe-west3"
  cluster_name = "usercentrics-production2"
  service_namespace = "production"
  service_name = "privacy-proxy-svc"
}

# 1.1. GKE Istio BE Availability
resource "google_monitoring_slo" "istio_be_avail_slo_sdp" {
  service = data.google_monitoring_cluster_istio_service.privacy-proxy-svc.service_id
  slo_id = "privacy-proxy-svc-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"privacy-proxy-svc\"",
        join(" OR ", [
          "metric.labels.response_code>499",
          "metric.labels.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"privacy-proxy-svc\"",
        "metric.labels.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.2. GKE Istio Latency
resource "google_monitoring_slo" "istio_be_lat_slo_sdp" {
  service = data.google_monitoring_cluster_istio_service.privacy-proxy-svc.service_id
  slo_id = "privacy-proxy-svc-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"privacy-proxy-svc\""
      ])

      range {
        max = 300
        min = 0
      }
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2. Cloud Storage - Privacy Proxy static assets
resource "google_monitoring_custom_service" "app-hitmanjs" {
  service_id = "app-hitmanjs"
  display_name = "Privacy Proxy App"
}

# 2.1. CS LB Availability
resource "google_monitoring_slo" "cs_lb_avail_slo_sdp" {
  service = google_monitoring_custom_service.app-hitmanjs.service_id
  slo_id = "app-hitmanjs-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-hitmanjs\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-hitmanjs\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2.2. CS LB Latency
resource "google_monitoring_slo" "cs_lb_lat_slo_sdp" {
  service = google_monitoring_custom_service.app-hitmanjs.service_id
  slo_id = "app-hitmanjs-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-hitmanjs\""
      ])

      range {
        max = 100
        min = 0
      }
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2.3. CS BE Availability
resource "google_monitoring_slo" "cs_be_avail_slo_sdp" {
  service = google_monitoring_custom_service.app-hitmanjs.service_id
  slo_id = "app-hitmanjs-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"app-hitmanjs\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"app-hitmanjs\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3. GKE - Crawler
data "google_monitoring_cluster_istio_service" "service-crawler-svc" {
  location = "europe-west3"
  cluster_name = "usercentrics-production2"
  service_namespace = "production"
  service_name = "service-crawler-svc"
}

# 3.1. GKE Istio BE Availability
resource "google_monitoring_slo" "istio_2_be_avail_slo_sdp" {
  service = data.google_monitoring_cluster_istio_service.service-crawler-svc.service_id
  slo_id = "service-crawler-svc-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"service-crawler-svc\"",
        join(" OR ", [
          "metric.labels.response_code>499",
          "metric.labels.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"service-crawler-svc\"",
        "metric.labels.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3.2. GKE Istio Latency
resource "google_monitoring_slo" "istio_2_be_lat_slo_sdp" {
  service = data.google_monitoring_cluster_istio_service.service-crawler-svc.service_id
  slo_id = "service-crawler-svc-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "metric.labels.destination_service_name=\"service-crawler-svc\""
      ])

      range {
        max = 300
        min = 0
      }
    }
  }

  goal = 0.99
  rolling_period_days = 1
}
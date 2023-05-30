# Duda Services
# 1. App Engine - Duda API without LoadBalancer!
data "google_monitoring_app_engine_service" "service-duda-api-prod" {
  module_id = "service-duda-api-prod"
}

# 1.1. AE BE Availability
resource "google_monitoring_slo" "ae_be_avail_slo_duda" {
  service = data.google_monitoring_app_engine_service.service-duda-api-prod.service_id
  slo_id = "service-duda-api-prod-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"service-duda-api-prod\"",
        join(" OR ", [
          "metric.label.response_code>499",
          "metric.label.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"service-duda-api-prod\"",
        "metric.label.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.2. AE BE Latency
resource "google_monitoring_slo" "ae_be_lat_slo_duda" {
  service = data.google_monitoring_app_engine_service.service-duda-api-prod.service_id
  slo_id = "service-duda-api-prod-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_latencies\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"service-duda-api-prod\""
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

# 2. Cloud Storage - Duda App
resource "google_monitoring_custom_service" "app-duda-fe" {
  service_id = "app-duda-fe"
  display_name = "Duda App"
}

# 2.1. CS LB Availability
resource "google_monitoring_slo" "cs_lb_avail_slo_duda" {
  service = google_monitoring_custom_service.app-duda-fe.service_id
  slo_id = "app-duda-fe-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"duda-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-duda-fe\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"duda-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-duda-fe\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2.2. CS LB Latency
resource "google_monitoring_slo" "cs_lb_lat_slo_duda" {
  service = google_monitoring_custom_service.app-duda-fe.service_id
  slo_id = "app-duda-fe-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"duda-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-duda-fe\""
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
resource "google_monitoring_slo" "cs_be_avail_slo_duda" {
  service = google_monitoring_custom_service.app-duda-fe.service_id
  slo_id = "app-duda-fe-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"app-duda-fe\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"app-duda-fe\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

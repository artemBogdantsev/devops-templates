# Partner API (AppEngine only)
# 1. App Engine - Partner API
data "google_monitoring_app_engine_service" "api-v2-prod-public" {
  module_id = "api-v2-prod-public"
}

# 1.1. LB Availability
resource "google_monitoring_slo" "ae_lb_avail_slo_partner" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-public.service_id
  slo_id = "api-v2-prod-public-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-public-lb\"",
        join(" OR ", [
          "metric.label.response_code_class>499",
          "metric.label.response_code_class<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-public-lb\"",
        "metric.label.response_code_class<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.2. LB Latency
resource "google_monitoring_slo" "ae_lb_lat_slo_partner" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-public.service_id
  slo_id = "api-v2-prod-public-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/total_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-public-lb\""
      ])

      range {
        max = 300 # TODO: adjust if needed
        min = 0
      }
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.3. AE BE Availability
resource "google_monitoring_slo" "ae_be_avail_slo_partner" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-public.service_id
  slo_id = "api-v2-prod-public-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-public\"",
        join(" OR ", [
          "metric.label.response_code>499",
          "metric.label.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-public\"",
        "metric.label.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.4. AE BE Latency
resource "google_monitoring_slo" "ae_be_lat_slo_partner" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-public.service_id
  slo_id = "api-v2-prod-public-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_latencies\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-public\""
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

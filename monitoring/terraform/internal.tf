# Internal services incl. Permission Manager
# 1. App Engine - Internal API
data "google_monitoring_app_engine_service" "api-v2-prod-internal" {
  module_id = "api-v2-prod-internal"
}

# 1.1. LB Availability
resource "google_monitoring_slo" "ae_lb_avail_slo_internal" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-internal.service_id
  slo_id = "api-v2-prod-internal-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-internal-lb\"",
        join(" OR ", [
          "metric.label.response_code_class>499",
          "metric.label.response_code_class<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-internal-lb\"",
        "metric.label.response_code_class<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.2. LB Latency
resource "google_monitoring_slo" "ae_lb_lat_slo_internal" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-internal.service_id
  slo_id = "api-v2-prod-internal-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/total_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-internal-lb\""
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
resource "google_monitoring_slo" "ae_be_avail_slo_internal" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-internal.service_id
  slo_id = "api-v2-prod-internal-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-internal\"",
        join(" OR ", [
          "metric.label.response_code>499",
          "metric.label.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-internal\"",
        "metric.label.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.4. AE BE Latency
resource "google_monitoring_slo" "ae_be_lat_slo_internal" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-internal.service_id
  slo_id = "api-v2-prod-internal-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_latencies\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-internal\""
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

# 2. Cloud Storage - Admin UI
resource "google_monitoring_custom_service" "app-admin-interface-production" {
  service_id = "app-admin-interface-production"
  display_name = "Admin UI"
}

# 2.1. CS LB Availability
resource "google_monitoring_slo" "cs_lb_avail_slo_internal" {
  service = google_monitoring_custom_service.app-admin-interface-production.service_id
  slo_id = "app-admin-interface-production-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-admin-interface-production\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-admin-interface-production\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2.2. CS LB Latency
resource "google_monitoring_slo" "cs_lb_lat_slo_internal" {
  service = google_monitoring_custom_service.app-admin-interface-production.service_id
  slo_id = "app-admin-interface-production-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-admin-interface-production\""
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
resource "google_monitoring_slo" "cs_be_avail_slo_internal" {
  service = google_monitoring_custom_service.app-admin-interface-production.service_id
  slo_id = "app-admin-interface-production-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"app-admin-interface-production\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"app-admin-interface-production\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3. Cloud Storage - Permission Manager UI (account.uc.com)

resource "google_monitoring_custom_service" "app-permission-manager" {
  service_id = "app-permission-manager"
  display_name = "Permission Manager UI"
}

# 3.1. CS LB Availability
resource "google_monitoring_slo" "cs_2_lb_avail_slo_internal" {
  service = google_monitoring_custom_service.app-permission-manager.service_id
  slo_id = "app-permission-manager-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"account-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-permission-manager\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"account-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-permission-manager\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3.2. CS LB Latency
resource "google_monitoring_slo" "cs_2_lb_lat_slo_internal" {
  service = google_monitoring_custom_service.app-permission-manager.service_id
  slo_id = "app-permission-manager-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"account-usercentrics-eu\"",
        "resource.label.backend_target_name=\"app-permission-manager\""
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

# 3.3. CS BE Availability
resource "google_monitoring_slo" "cs_2_be_avail_slo_internal" {
  service = google_monitoring_custom_service.app-permission-manager.service_id
  slo_id = "app-permission-manager-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"app-permission-manager\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"app-permission-manager\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 4. AppEngine - Permission Manager API
data "google_monitoring_app_engine_service" "service-permission-manager" {
  module_id = "service-permission-manager"
}

# 4.1. LB Availability
resource "google_monitoring_slo" "ae_2_lb_avail_slo_internal" {
  service = data.google_monitoring_app_engine_service.service-permission-manager.service_id
  slo_id = "service-permission-manager-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"service-permission-manager-lb\"",
        join(" OR ", [
          "metric.label.response_code_class>499",
          "metric.label.response_code_class<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"service-permission-manager-lb\"",
        "metric.label.response_code_class<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 4.2. LB Latency
resource "google_monitoring_slo" "ae_2_lb_lat_slo_internal" {
  service = data.google_monitoring_app_engine_service.service-permission-manager.service_id
  slo_id = "service-permission-manager-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/total_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"service-permission-manager-lb\""
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
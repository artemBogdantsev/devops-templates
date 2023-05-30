# CMP important services
# 1. App Engine - GraphQL CMP API
data "google_monitoring_app_engine_service" "api-v2-prod-consent" {
  module_id = "api-v2-prod-consent"
}

# 1.1. LB Availability
resource "google_monitoring_slo" "ae_lb_avail_slo" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-consent.service_id
  slo_id = "api-v2-prod-consent-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-consent-lb\"",
        join(" OR ", [
          "metric.label.response_code_class>499",
          "metric.label.response_code_class<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-consent-lb\"",
        "metric.label.response_code_class<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.2. LB Latency
resource "google_monitoring_slo" "ae_lb_lat_slo" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-consent.service_id
  slo_id = "api-v2-prod-consent-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/total_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"api-v2-prod-consent-lb\""
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
resource "google_monitoring_slo" "ae_be_avail_slo" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-consent.service_id
  slo_id = "api-v2-prod-consent-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-consent\"",
        join(" OR ", [
          "metric.label.response_code>499",
          "metric.label.response_code<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-consent\"",
        "metric.label.response_code<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 1.4. AE BE Latency
resource "google_monitoring_slo" "ae_be_lat_slo" {
  service = data.google_monitoring_app_engine_service.api-v2-prod-consent.service_id
  slo_id = "api-v2-prod-consent-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_latencies\"",
        "resource.type=\"gae_app\"",
        "resource.label.module_id=\"api-v2-prod-consent\""
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

# 2. Cloud Storage - Browser UI/SDK
resource "google_monitoring_custom_service" "app-browser-ui" {
  service_id = "app-browser-ui"
  display_name = "Browser UI Bucket Service (UI/SDK)"
}

# 2.1. CS LB Availability
resource "google_monitoring_slo" "cs_lb_avail_slo" {
  service = google_monitoring_custom_service.app-browser-ui.service_id
  slo_id = "app-browser-ui-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-browser-ui\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-browser-ui\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 2.2. CS LB Latency
resource "google_monitoring_slo" "cs_lb_lat_slo" {
  service = google_monitoring_custom_service.app-browser-ui.service_id
  slo_id = "app-browser-ui-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"app-<YOUR_DOMAIN>-eu\"",
        "resource.label.backend_target_name=\"app-browser-ui\""
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
resource "google_monitoring_slo" "cs_be_avail_slo" {
  service = google_monitoring_custom_service.app-browser-ui.service_id
  slo_id = "app-browser-ui-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"app-browser-ui\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"app-browser-ui\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3. Cloud Storage - Settings/Translations static assets

resource "google_monitoring_custom_service" "staticfiles" {
  service_id = "staticfiles"
  display_name = "Static Assets Bucket Service (Settings/Translation)"
}

# 3.1. CS LB Availability
resource "google_monitoring_slo" "cs_2_lb_avail_slo" {
  service = google_monitoring_custom_service.staticfiles.service_id
  slo_id = "staticfiles-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"static-assets-<YOUR_DOMAIN>\"",
        "resource.label.backend_target_name=\"staticfiles\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"static-assets-<YOUR_DOMAIN>\"",
        "resource.label.backend_target_name=\"staticfiles\"",
        "metric.label.response_code_class<399"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 3.2. CS LB Latency
resource "google_monitoring_slo" "cs_2_lb_lat_slo" {
  service = google_monitoring_custom_service.staticfiles.service_id
  slo_id = "staticfiles-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"static-assets-<YOUR_DOMAIN>\"",
        "resource.label.backend_target_name=\"staticfiles\""
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
resource "google_monitoring_slo" "cs_2_be_avail_slo" {
  service = google_monitoring_custom_service.staticfiles.service_id
  slo_id = "staticfiles-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "metric.label.method=\"ReadObject\"",
        "resource.label.bucket_name=\"staticfiles\"",
        "metric.label.response_code!=\"FAILED_PRECONDITION\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"storage.googleapis.com/api/request_count\"",
        "resource.type=\"gcs_bucket\"",
        "resource.label.bucket_name=\"staticfiles\"",
        "metric.label.method=\"ReadObject\"",
        "metric.label.response_code=\"OK\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 4. Cloud Run - Template Aggregator
resource "google_monitoring_custom_service" "template-aggregator" {
  service_id = "template-aggregator"
  display_name = "Template Aggregator Service"
}

# 4.1. CR LB Availability
resource "google_monitoring_slo" "cr_lb_avail_slo" {
  service = google_monitoring_custom_service.template-aggregator.service_id
  slo_id = "template-aggregator-slo-lb-avail-day"
  display_name = "99% - LB Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"template-aggregator\"",
        join(" OR ", [
          "metric.label.response_code_class>499",
          "metric.label.response_code_class<399"
        ])
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/request_count\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"template-aggregator\"",
        "metric.label.response_code_class<299"
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 4.2. CR LB Latency
resource "google_monitoring_slo" "cr_lb_lat_slo" {
  service = google_monitoring_custom_service.template-aggregator.service_id
  slo_id = "template-aggregator-slo-lb-lat-day"
  display_name = "99% - LB Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"loadbalancing.googleapis.com/https/total_latencies\"",
        "resource.type=\"https_lb_rule\"",
        "resource.label.url_map_name=\"template-aggregator\""
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

# 4.3. CR BE Availability
resource "google_monitoring_slo" "cr_be_avail_slo" {
  service = google_monitoring_custom_service.template-aggregator.service_id
  slo_id = "template-aggregator-slo-be-avail-day"
  display_name = "99% - BE Availability - Rolling Day"

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.service_name=\"template-aggregator\"",
        "metric.label.response_code_class!=\"4xx\""
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.service_name=\"template-aggregator\"",
        "metric.label.response_code_class=\"2xx\""
      ])
    }
  }

  goal = 0.99
  rolling_period_days = 1
}

# 4.4. CR BE Latency
resource "google_monitoring_slo" "cr_be_lat_slo" {
  service = google_monitoring_custom_service.template-aggregator.service_id
  slo_id = "template-aggregator-slo-be-lat-day"
  display_name = "99% - BE Latency - Rolling Day"

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_latencies\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.service_name=\"template-aggregator\""
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

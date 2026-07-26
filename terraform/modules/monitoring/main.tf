resource "google_logging_metric" "pubsub_dlq" {
  project = var.project_id
  name    = "${replace(var.name_prefix, "-", "_")}_pubsub_dead_letter_messages"
  filter  = "resource.type=\"pubsub_subscription\" AND protoPayload.methodName:\"google.pubsub\" AND severity>=WARNING"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_notification_channel" "email" {
  count        = var.notification_email == "" ? 0 : 1
  project      = var.project_id
  display_name = "${var.name_prefix} data platform alerts"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "pubsub_backlog" {
  project      = var.project_id
  display_name = "${var.name_prefix} Pub/Sub backlog SLO"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Oldest unacked message exceeds 15 minutes"

    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 900

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.name]
}

resource "google_monitoring_dashboard" "lakehouse" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "${var.name_prefix} retail lakehouse"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "Pub/Sub backlog age"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\" resource.type=\"pubsub_subscription\""
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MAX"
                  }
                }
              }
            }]
          }
        },
        {
          title = "GKE CPU requested cores"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/container/cpu/request_cores\" resource.type=\"k8s_container\""
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}

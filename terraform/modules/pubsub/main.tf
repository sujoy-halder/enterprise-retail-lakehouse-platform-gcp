locals {
  sources = {
    pos_transactions = {
      retention = "604800s"
      schema = {
        transaction_id = "STRING"
        store_id       = "STRING"
        event_time     = "TIMESTAMP"
      }
    }
    inventory = {
      retention = "604800s"
      schema = {
        sku        = "STRING"
        store_id   = "STRING"
        event_time = "TIMESTAMP"
      }
    }
    customer_activity = {
      retention = "604800s"
      schema = {
        customer_id = "STRING"
        event_type  = "STRING"
        event_time  = "TIMESTAMP"
      }
    }
    supply_chain_events = {
      retention = "604800s"
      schema = {
        shipment_id = "STRING"
        carrier     = "STRING"
        event_time  = "TIMESTAMP"
      }
    }
    recommendation_events = {
      retention = "604800s"
      schema = {
        customer_id = "STRING"
        product_id  = "STRING"
        event_time  = "TIMESTAMP"
      }
    }
    warehouse_iot = {
      retention = "604800s"
      schema = {
        device_id  = "STRING"
        metric     = "STRING"
        event_time = "TIMESTAMP"
      }
    }
  }

  publisher_bindings = {
    for item in flatten([
      for topic_key in keys(local.sources) : [
        for service_account in var.publisher_service_accounts : {
          key             = "${topic_key}-${service_account}"
          topic_key       = topic_key
          service_account = service_account
        }
      ]
    ]) : item.key => item
  }

  subscriber_bindings = {
    for item in flatten([
      for topic_key in keys(local.sources) : [
        for service_account in var.subscriber_service_accounts : {
          key             = "${topic_key}-${service_account}"
          topic_key       = topic_key
          service_account = service_account
        }
      ]
    ]) : item.key => item
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_pubsub_topic" "source" {
  for_each = local.sources

  project                    = var.project_id
  name                       = "${var.name_prefix}-${replace(each.key, "_", "-")}"
  labels                     = var.labels
  message_retention_duration = each.value.retention
}

resource "google_pubsub_topic" "dead_letter" {
  for_each = local.sources

  project = var.project_id
  name    = "${var.name_prefix}-${replace(each.key, "_", "-")}-dlq"
  labels  = merge(var.labels, { purpose = "dead-letter" })
}

resource "google_pubsub_subscription" "source" {
  for_each = local.sources

  project                    = var.project_id
  name                       = "${var.name_prefix}-${replace(each.key, "_", "-")}-sub"
  topic                      = google_pubsub_topic.source[each.key].id
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
  retain_acked_messages      = false
  enable_message_ordering    = true
  labels                     = var.labels

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter[each.key].id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = local.publisher_bindings

  project = var.project_id
  topic   = google_pubsub_topic.source[each.value.topic_key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${each.value.service_account}"
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  for_each = local.subscriber_bindings

  project      = var.project_id
  subscription = google_pubsub_subscription.source[each.value.topic_key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${each.value.service_account}"
}

resource "google_pubsub_topic_iam_member" "pubsub_dead_letter_publisher" {
  for_each = google_pubsub_topic.dead_letter

  project = var.project_id
  topic   = each.value.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "pubsub_dead_letter_subscriber" {
  for_each = google_pubsub_subscription.source

  project      = var.project_id
  subscription = each.value.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

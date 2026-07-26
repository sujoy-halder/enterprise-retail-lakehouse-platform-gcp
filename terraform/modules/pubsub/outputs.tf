output "topic_names" {
  value = {
    for key, topic in google_pubsub_topic.source : key => topic.name
  }
}

output "subscription_names" {
  value = {
    for key, subscription in google_pubsub_subscription.source : key => subscription.name
  }
}


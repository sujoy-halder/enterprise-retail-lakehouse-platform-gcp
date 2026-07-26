output "dataset_ids" {
  value = {
    for key, dataset in google_bigquery_dataset.datasets : key => dataset.dataset_id
  }
}


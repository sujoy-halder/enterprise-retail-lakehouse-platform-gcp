resource "random_id" "bucket_suffix" {
  byte_length = 3
}

locals {
  layers = ["bronze", "silver", "gold", "checkpoints", "quarantine", "temp"]

  buckets = {
    for item in flatten([
      for region in var.regions : [
        for layer in local.layers : {
          key    = "${layer}-${region}"
          layer  = layer
          region = region
        }
      ]
    ]) : item.key => item
  }
}

resource "google_storage_bucket" "lake" {
  for_each = local.buckets

  project                     = var.project_id
  name                        = lower("${var.name_prefix}-${each.value.layer}-${each.value.region}-${random_id.bucket_suffix.hex}")
  location                    = upper(each.value.region)
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = merge(var.labels, { lake_layer = each.value.layer, region = each.value.region })

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  lifecycle_rule {
    condition {
      age                   = each.value.layer == "bronze" ? 365 : 90
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = each.value.layer == "temp" ? 7 : 2555
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "data_admin" {
  for_each = google_storage_bucket.lake

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.data_service_account_email}"
}

resource "google_storage_bucket_iam_member" "composer_admin" {
  for_each = google_storage_bucket.lake

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.composer_service_account_email}"
}


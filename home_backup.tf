resource "random_id" "backup_id" {
  byte_length = "2"
  prefix      = "home-backup-"
}

resource "google_project" "backup_project" {
  name            = "home-backup"
  project_id      = random_id.backup_id.hex
  billing_account = var.billing_account_id
  org_id          = var.org_id
  labels          = var.labels
}

resource "google_project_service" "backup_services" {
  for_each           = toset(var.services)
  service            = each.key
  project            = google_project.backup_project.project_id
  disable_on_destroy = false
}

resource "google_storage_bucket" "synology_backup" {
  provider      = google
  name          = "synology-backup"
  location      = "US"
  force_destroy = true
  project       = google_project.backup_project.project_id
  storage_class = "ARCHIVE"
}

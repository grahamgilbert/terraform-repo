resource "random_id" "id" {
  byte_length = "2"
  prefix      = "home-backup-"
}

resource "google_project" "backup_project" {
  name            = "home-backup"
  project_id      = random_id.id.hex
  billing_account = var.billing_account_id
  org_id          = var.org_id
  labels          = var.labels
}

resource "google_project_service" "service" {
  for_each           = toset(var.services)
  service            = each.key
  project            = google_project.backup_project.project_id
  disable_on_destroy = false
}

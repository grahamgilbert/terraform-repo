resource "random_id" "salversion_id" {
  byte_length = "2"
  prefix      = "salversion-"
}

resource "google_project" "salversion_project" {
  name            = "salversion"
  project_id      = random_id.salversion_id.hex
  billing_account = var.billing_account_id
  org_id          = var.org_id
  labels          = var.labels
}

resource "google_project_service" "salversion_services" {
  for_each           = toset(var.services)
  service            = each.key
  project            = google_project.salversion_project.project_id
  disable_on_destroy = false
}

resource "google_service_account" "deploy_account" {
  account_id   = "deploy-account"
  display_name = "Deploy Account"
  project      = google_project.salversion_project.project_id
}

resource "google_service_account_iam_member" "deployer" {
  service_account_id = google_service_account.deploy_account.name
  role               = "roles/appengine.appAdmin"
  member             = "serviceAccount:${google_service_account.deploy_account.email}"
  project            = google_project.salversion_project.project_id
}

resource "google_service_account_iam_member" "service_account" {
  service_account_id = google_service_account.deploy_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy_account.email}"
  project            = google_project.salversion_project.project_id
}

resource "google_service_account_iam_member" "service_admin" {
  service_account_id = google_service_account.deploy_account.name
  role               = "roles/appengine.serviceAdmin"
  member             = "serviceAccount:${google_service_account.deploy_account.email}"
  project            = google_project.salversion_project.project_id
}

resource "google_service_account_iam_member" "build_editor" {
  service_account_id = google_service_account.deploy_account.name
  role               = "(roles/cloudbuild.builds.editor"
  member             = "serviceAccount:${google_service_account.deploy_account.email}"
  project            = google_project.salversion_project.project_id
}

resource "google_app_engine_application" "salversion" {
  project       = google_project.salversion_project.project_id
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"
}

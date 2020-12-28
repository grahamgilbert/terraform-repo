resource "google_storage_bucket" "website" {
  provider = google
  name     = "grahamgilbert-website"
  location = "US"
}

resource "google_storage_default_object_access_control" "website_read" {
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

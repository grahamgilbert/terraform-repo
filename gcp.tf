provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# GCP beta provider
provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_global_address" "website" {
  provider = google
  name     = "website-lb-ip"
}

resource "google_compute_backend_bucket" "website" {
  provider    = google
  name        = "website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Get the managed DNS zone
# data "google_dns_managed_zone" "gcp_coffeetime_dev" {
#   provider = google
#   name     = "gcp-coffeetime-dev"
# }

# # Add the IP to the DNS
# resource "google_dns_record_set" "website" {
#   provider     = google
#   name         = "website.${data.google_dns_managed_zone.gcp_coffeetime_dev.dns_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.gcp_coffeetime_dev.name
#   rrdatas      = [google_compute_global_address.website.address]
# }

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "website-cert"
  managed {
    domains = ["test.grahamgilbert.com"]
  }
}

# GCP URL MAP
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website.self_link
}

# GCP target proxy
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}

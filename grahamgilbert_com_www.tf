resource "random_id" "id" {
  byte_length = "2"
  prefix      = "grahamgilbert-com-www-"
}

resource "google_project" "gg_project" {
  name            = "grahamgilbert-com-www"
  project_id      = random_id.id.hex
  billing_account = var.billing_account_id
  org_id          = var.org_id
  labels          = var.labels
}

resource "google_project_service" "gg_service" {
  for_each           = toset(var.services)
  service            = each.key
  project            = google_project.gg_project.project_id
  disable_on_destroy = false
}


resource "google_storage_bucket" "website" {
  provider = google
  name     = "grahamgilbert-website"
  location = "US"
  project  = google_project.gg_project.project_id
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_default_object_access_control" "website_read" {
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_compute_global_address" "website" {
  provider = google
  name     = "website-lb-ip"
  project  = google_project.gg_project.project_id
}

resource "google_compute_backend_bucket" "website" {
  provider    = google
  name        = "website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
  project     = google_project.gg_project.project_id
}

# Get the managed DNS zone
# data "google_dns_managed_zone" "gcp_coffeetime_dev" {
#   provider = google
#   name     = "gcp-coffeetime-dev"
# project  = google_project.dns.project_id
# }

# # Add the IP to the DNS
# resource "google_dns_record_set" "website" {
#   provider     = google
#   name         = "website.${data.google_dns_managed_zone.gcp_coffeetime_dev.dns_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.gcp_coffeetime_dev.name
#   rrdatas      = [google_compute_global_address.website.address]
# project  = google_project.dns.project_id
# }

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "grahamgilbert-dot-com-cert"
  managed {
    domains = [var.root_domain_name]
  }
  project = google_project.gg_project.project_id
}

# GCP URL MAP
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website.self_link
  project         = google_project.gg_project.project_id
}

# GCP target proxy
resource "google_compute_target_https_proxy" "website" {
  provider         = google
  name             = "gg-https-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
  project          = google_project.gg_project.project_id
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "website" {
  provider              = google
  name                  = "gg-website-lb-https"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
  project               = google_project.gg_project.project_id
}

resource "google_compute_url_map" "https_redirect" {
  name    = "gg-website-https-redirect"
  project = google_project.gg_project.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_redirect" {
  name    = "gg-website-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
  project = google_project.gg_project.project_id
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  name       = "gg-website-lb-http"
  target     = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.website.address
  project    = google_project.gg_project.project_id
}

resource "google_service_account" "deploy_account" {
  account_id   = "deploy-account"
  display_name = "Deploy Account"
  project      = google_project.gg_project.project_id
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.deploy_account.email}"
}

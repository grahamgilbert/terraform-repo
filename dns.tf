resource "random_id" "dns_id" {
  byte_length = "2"
  prefix      = "grahamgilbert-com-dns-"
}

resource "google_project" "dns_project" {
  name            = "grahamgilbert-com-dns"
  project_id      = random_id.dns_id.hex
  billing_account = var.billing_account_id
  org_id          = var.org_id
  labels          = var.labels
}

module "dns-public-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "3.0.0"
  project_id = google_project.dns_project.project_id
  type       = "public"
  name       = "grahamgilbertdotcom"
  domain     = "grahamgilbert.com."

  recordsets = [
    {
      name = ""
      type = "A"
      ttl  = 60
      records = [
        google_compute_global_address.website.address,
      ]
    },
    {
      name = ""
      type = "MX"
      ttl  = 300
      records = [
        "60 aspmx4.googlemail.com",
        "10 aspmx.l.google.com",
        "50 aspmx3.googlemail.com",
        "20 alt2.aspmx.l.google.com",
        "40 aspmx2.googlemail.com",
        "30 alt1.aspmx.l.google.com",
      ]
    },
    {
      name = "server.grahamgilbert.com"
      type = "CNAME"
      ttl  = 300
      records = [
        "gg-home.ddns.net",
      ]
    },
    {
      name = "mail.grahamgilbert.com"
      type = "CNAME"
      ttl  = 300
      records = [
        "ghs.google.com",
      ]
    },
    {
      name = "calendar.grahamgilbert.com"
      type = "CNAME"
      ttl  = 300
      records = [
        "ghs.google.com",
      ]
    },
    {
      name = "link.grahamgilbert.com"
      type = "CNAME"
      ttl  = 300
      records = [
        "ghs.google.com",
      ]
    },
    {
      name = "sites.grahamgilbert.com"
      type = "CNAME"
      ttl  = 300
      records = [
        "ghs.google.com",
      ]
    },
  ]
}

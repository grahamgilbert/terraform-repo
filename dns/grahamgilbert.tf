variable "gsuite_subdomains" {
  default = [
    "mail.grahamgilbert.com",
    "calendar.grahamgilbert.com",
    "link.grahamgilbert.com",
    "sites.grahamgilbert.com",
  ]
}

# The below is default, but in case we ever need it, here it is

# resource "aws_route53_record" "grahamgilbert_com_ns" {
#   zone_id = "${aws_route53_zone.main.zone_id}"
#   type    = "NS"
#   name    = "${var.main_zone_host}"

#   records = [
#     "${aws_route53_zone.main.name_servers.0}",
#     "${aws_route53_zone.main.name_servers.1}",
#     "${aws_route53_zone.main.name_servers.2}",
#     "${aws_route53_zone.main.name_servers.3}",
#   ]

#   ttl = 172800
# }

resource "aws_route53_record" "grahamgilbert_root" {
  zone_id = "${var.zone_id}"
  type    = "A"
  name    = "${var.main_zone_host}"

  alias {
    name                   = "${var.main_cloudfront_name}"
    zone_id                = "${var.main_cloudfront_hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.zone_id}"
  type    = "CNAME"
  name    = "www.grahamgilbert.com"
  ttl     = 300
  records = [var.main_zone_host]
}

resource "aws_route53_record" "gsuite_subdomains" {
  zone_id = "${var.zone_id}"
  count   = "${length(var.gsuite_subdomains)}"
  type    = "CNAME"
  name    = "${element(var.gsuite_subdomains, count.index)}"
  ttl     = 300
  records = ["ghs.google.com"]
}

resource "aws_route53_record" "server_alias" {
  zone_id = "${var.zone_id}"
  type    = "CNAME"
  name    = "server.grahamgilbert.com"
  ttl     = 300
  records = ["gg-home.ddns.net"]
}

resource "aws_route53_record" "mx" {
  zone_id = "${var.zone_id}"
  type    = "MX"
  name    = "${var.main_zone_host}"
  ttl     = 300

  records = [
    "60 aspmx4.googlemail.com",
    "10 aspmx.l.google.com",
    "50 aspmx3.googlemail.com",
    "20 alt2.aspmx.l.google.com",
    "40 aspmx2.googlemail.com",
    "30 alt1.aspmx.l.google.com",
  ]
}

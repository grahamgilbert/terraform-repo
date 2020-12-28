module "dns" {
  source                         = "./dns"
  main_cloudfront_name           = aws_cloudfront_distribution.www_distribution.domain_name
  main_cloudfront_hosted_zone_id = aws_cloudfront_distribution.www_distribution.hosted_zone_id
  gcp_load_balancer_ip           = google_compute_global_address.website.address
}

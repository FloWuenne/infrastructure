resource "aws_route53_record" "plausible" {
  allow_overwrite = true
  zone_id         = var.zone_galaxyproject_eu
  name            = "plausible.galaxyproject.eu"
  type            = "A"
  ttl             = "600"
  records         = ["192.52.44.75"]
}

resource "aws_route53_record" "apollo-main" {
  allow_overwrite = true
  zone_id         = var.zone_galaxyproject_eu
  name            = "apollo.internal.galaxyproject.eu"
  type            = "A"
  ttl             = "600"
  records         = ["10.5.68.7"]
}

resource "aws_route53_record" "ftp" {
  allow_overwrite = true
  zone_id         = var.zone_usegalaxy_eu
  name            = "ftp.usegalaxy.eu"
  type            = "A"
  ttl             = "600"
  records         = ["132.230.223.213"]
}

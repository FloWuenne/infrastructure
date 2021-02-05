variable "gat-count-eu" {
  default = 0
}

data "openstack_images_image_v2" "gat-image-eu" {
  name = "Ubuntu 20.04"
}

# Random passwords for the VMs, easier to type/remember for the non-ssh key
# users.
resource "random_pet" "training-vm-eu" {
  keepers = {
    image  = "${data.openstack_images_image_v2.gat-image-eu.id}"
    region = "eu"
  }

  length = 2
  count  = "${var.gat-count-eu}"
}

# The VMs themselves.
resource "openstack_compute_instance_v2" "training-vm-eu" {
  name            = "gat-${count.index}.eu.training.galaxyproject.eu"
  # Not required when booting from volume
  image_id        = "${data.openstack_images_image_v2.gat-image-eu.id}"
  flavor_name     = "c1.galaxy_admin_training_c8m16d50"
  security_groups = ["public", "public-ping", "public-web2", "egress", "public-gat", "public-amqp"]

  key_pair = "cloud2"

  network {
    name = "public"
  }

  # Update user password
  user_data = <<-EOF
    #cloud-config
    chpasswd:
      list: |
        ubuntu:${element(random_pet.training-vm-eu.*.id, count.index)}
      expire: False
    runcmd:
     - [ sed, -i, s/PasswordAuthentication no/PasswordAuthentication yes/, /etc/ssh/sshd_config ]
     - [ systemctl, restart, ssh ]
  EOF

  count = "${var.gat-count-eu}"
}

# Setup a DNS record for the VMs to make access easier (and https possible.)
resource "aws_route53_record" "training-vm-eu" {
  zone_id = "${aws_route53_zone.training-gxp-eu.zone_id}"
  name    = "gat-${count.index}.eu.training.galaxyproject.eu"
  type    = "A"
  ttl     = "3600"
  records = ["${element(openstack_compute_instance_v2.training-vm-eu.*.access_ip_v4, count.index)}"]
  count   = "${var.gat-count-eu}"
}

# Only for the REAL gat.
resource "aws_route53_record" "training-vm-eu-gxit-wildcard" {
  zone_id = "${aws_route53_zone.training-gxp-eu.zone_id}"
  name    = "*.interactivetoolentrypoint.interactivetool.gat-${count.index}.eu.training.galaxyproject.eu"
  type    = "CNAME"
  ttl     = "3600"
  records = ["gat-${count.index}.eu.training.galaxyproject.eu"]
  count   = "${var.gat-count-eu}"
}

# Outputs to be consumed by admins
output "training_ips-eu" {
  value = ["${openstack_compute_instance_v2.training-vm-eu.*.access_ip_v4}"]
}

output "training_pws-eu" {
  value     = ["${random_pet.training-vm-eu.*.id}"]
  sensitive = true
}

output "training_dns-eu" {
  value = ["${aws_route53_record.training-vm-eu.*.name}"]
}


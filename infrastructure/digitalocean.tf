provider "digitalocean" {
  token   = "${var.digitalocean_token}"
  version = "~> 1.9"
}

resource "digitalocean_project" "jeanmertz" {
  name        = "jeanmertz.com"
  description = "all resources related to jeanmertz.com"
  purpose     = "Website"
  environment = "Production"
  resources = [
    "${digitalocean_droplet.jeanmertz.urn}",
    "${digitalocean_domain.jeanmertz.urn}",
    "${digitalocean_floating_ip.jeanmertz.urn}",
  ]
}

resource "digitalocean_tag" "production" {
  name = "production"
}

resource "digitalocean_tag" "jeanmertz" {
  name = "jeanmertz-com"
}

resource "digitalocean_ssh_key" "jeanmertz" {
  name       = "Jean Mertz"
  public_key = "${var.ssh_public_key}"
}

resource "digitalocean_domain" "jeanmertz" {
  name = "jeanmertz.com"
}

resource "digitalocean_record" "root" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "A"
  name   = "@"
  value  = "${digitalocean_floating_ip.jeanmertz.ip_address}"
}

resource "digitalocean_record" "wildcard" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "A"
  name   = "*"
  value  = "${digitalocean_floating_ip.jeanmertz.ip_address}"
}

resource "digitalocean_record" "caa" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "CAA"
  name   = "@"
  value  = "letsencrypt.org."
  tag    = "issue"
  flags  = 1
}

resource "digitalocean_record" "email-mx-1" {
  domain   = "${digitalocean_domain.jeanmertz.name}"
  type     = "MX"
  name     = "@"
  value    = "in1-smtp.messagingengine.com."
  priority = 10
}

resource "digitalocean_record" "email-mx-2" {
  domain   = "${digitalocean_domain.jeanmertz.name}"
  type     = "MX"
  name     = "@"
  value    = "in2-smtp.messagingengine.com."
  priority = 20
}

resource "digitalocean_record" "email-spf" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:spf.messagingengine.com ?all"
}

resource "digitalocean_record" "email-dkim-1" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "CNAME"
  name   = "fm1._domainkey"
  value  = "fm1.jeanmertz.com.dkim.fmhosted.com."
}

resource "digitalocean_record" "email-dkim-2" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "CNAME"
  name   = "fm2._domainkey"
  value  = "fm2.jeanmertz.com.dkim.fmhosted.com."
}

resource "digitalocean_record" "email-dkim-3" {
  domain = "${digitalocean_domain.jeanmertz.name}"
  type   = "CNAME"
  name   = "fm3._domainkey"
  value  = "fm3.jeanmertz.com.dkim.fmhosted.com."
}

resource "digitalocean_firewall" "jeanmertz" {
  name = "ssh-and-http"

  droplet_ids = ["${digitalocean_droplet.jeanmertz.id}"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "234"
    source_addresses = ["${chomp(data.http.source_ip.body)}/32"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Network Time Protocol
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_floating_ip" "jeanmertz" {
  region = "${digitalocean_droplet.jeanmertz.region}"
}

resource "digitalocean_floating_ip_assignment" "jeanmertz" {
  ip_address = "${digitalocean_floating_ip.jeanmertz.ip_address}"
  droplet_id = "${digitalocean_droplet.jeanmertz.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_droplet" "jeanmertz" {
  image       = "53649892" # CoreOS 2247.5.0 (stable)
  name        = "jeanmertz.com"
  region      = "ams3"
  size        = "s-1vcpu-1gb"
  ipv6        = true
  resize_disk = false
  ssh_keys    = ["${digitalocean_ssh_key.jeanmertz.fingerprint}"]
  user_data   = "${data.ignition_config.jeanmertz.rendered}"
  tags = [
    "${digitalocean_tag.jeanmertz.id}",
    "${digitalocean_tag.production.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "${path.cwd}/check_health.sh ${self.ipv4_address}"
  }
}

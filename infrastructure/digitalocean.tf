locals {
  domains = ["jeanmertz.com", "ethical.engineer"]
}

provider "digitalocean" {
  token   = var.digitalocean_token
  version = "~> 1.9"
}

resource "digitalocean_project" "jeanmertz" {
  name        = "jeanmertz.com"
  description = "all resources related to jeanmertz.com"
  purpose     = "Website"
  environment = "Production"
  resources = concat(
    [for d in digitalocean_domain.domain : d.urn],
    [digitalocean_droplet.jeanmertz.urn, digitalocean_floating_ip.jeanmertz.urn],
  )
}

resource "digitalocean_tag" "production" {
  name = "production"
}

resource "digitalocean_tag" "jeanmertz" {
  name = "jeanmertz-com"
}

resource "digitalocean_ssh_key" "jeanmertz" {
  name       = "Jean Mertz"
  public_key = var.ssh_public_key
}

resource "digitalocean_domain" "domain" {
  for_each = toset(local.domains)

  name = each.key
}

resource "digitalocean_record" "root" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "A"
  name   = "@"
  value  = digitalocean_floating_ip.jeanmertz.ip_address
}

resource "digitalocean_record" "wildcard" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "A"
  name   = "*"
  value  = digitalocean_floating_ip.jeanmertz.ip_address
}

# see: https://www.fastmail.com/help/receive/domains-advanced.html#dnslist
resource "digitalocean_record" "mail-1" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "A"
  name   = "mail"
  value  = "66.111.4.147"
}

resource "digitalocean_record" "mail-2" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "A"
  name   = "mail"
  value  = "66.111.4.148"
}

resource "digitalocean_record" "caa" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "CAA"
  name   = "@"
  value  = "letsencrypt.org."
  tag    = "issue"
  flags  = 1
}

resource "digitalocean_record" "email-mx-1" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "@"
  value    = "in1-smtp.messagingengine.com."
  priority = 10
}

resource "digitalocean_record" "email-mx-1-wildcard" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "*"
  value    = "in1-smtp.messagingengine.com."
  priority = 10
}

# This is needed because we also set an "A" record on the `mail` subdomain,
# which would mask our wildcard MX record, preventing emails to be delivered to
# ...@mail.jeanmertz.com (not that this is in use right now, but let's prevent
# any surprises).
resource "digitalocean_record" "email-mx-1-mail" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "mail"
  value    = "in1-smtp.messagingengine.com."
  priority = 10
}

resource "digitalocean_record" "email-mx-2" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "@"
  value    = "in2-smtp.messagingengine.com."
  priority = 20
}

resource "digitalocean_record" "email-mx-2-wildcard" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "*"
  value    = "in2-smtp.messagingengine.com."
  priority = 20
}

# This is needed because we also set an "A" record on the `mail` subdomain,
# which would mask our wildcard MX record, preventing emails to be delivered to
# ...@mail.jeanmertz.com (not that this is in use right now, but let's prevent
# any surprises).
resource "digitalocean_record" "email-mx-2-mail" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "MX"
  name     = "mail"
  value    = "in2-smtp.messagingengine.com."
  priority = 20
}

resource "digitalocean_record" "email-spf" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:spf.messagingengine.com ?all"
}

resource "digitalocean_record" "email-dkim-1" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "CNAME"
  name   = "fm1._domainkey"
  value  = "fm1.${digitalocean_domain.domain[each.key].name}.dkim.fmhosted.com."
}

resource "digitalocean_record" "email-dkim-2" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "CNAME"
  name   = "fm2._domainkey"
  value  = "fm2.${digitalocean_domain.domain[each.key].name}.dkim.fmhosted.com."
}

resource "digitalocean_record" "email-dkim-3" {
  for_each = toset(local.domains)

  domain = digitalocean_domain.domain[each.key].name
  type   = "CNAME"
  name   = "fm3._domainkey"
  value  = "fm3.${digitalocean_domain.domain[each.key].name}.dkim.fmhosted.com."
}

resource "digitalocean_record" "email-discovery-submission" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "SRV"
  name     = "_submission._tcp.${digitalocean_domain.domain[each.key].name}"
  value    = "smtp.fastmail.com."
  priority = 0
  weight   = 0
  port     = 587
}

resource "digitalocean_record" "email-discovery-imaps" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "SRV"
  name     = "_imaps._tcp"
  value    = "imap.fastmail.com."
  priority = 0
  weight   = 0
  port     = 993
}

resource "digitalocean_record" "email-discovery-pop3s" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "SRV"
  name     = "_pop3s._tcp"
  value    = "pop.fastmail.com."
  priority = 0
  weight   = 0
  port     = 995
}

resource "digitalocean_record" "email-discovery-carddavs" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "SRV"
  name     = "_carddavs._tcp"
  value    = "carddav.fastmail.com."
  priority = 0
  weight   = 0
  port     = 443
}

resource "digitalocean_record" "email-discovery-caldavs" {
  for_each = toset(local.domains)

  domain   = digitalocean_domain.domain[each.key].name
  type     = "SRV"
  name     = "_caldavs._tcp"
  value    = "caldav.fastmail.com."
  priority = 0
  weight   = 0
  port     = 443
}

resource "digitalocean_firewall" "jeanmertz" {
  name = "ssh-and-http"

  droplet_ids = [digitalocean_droplet.jeanmertz.id]

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
  region = digitalocean_droplet.jeanmertz.region
}

resource "digitalocean_floating_ip_assignment" "jeanmertz" {
  ip_address = digitalocean_floating_ip.jeanmertz.ip_address
  droplet_id = digitalocean_droplet.jeanmertz.id

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
  ssh_keys    = [digitalocean_ssh_key.jeanmertz.fingerprint]
  user_data   = data.ignition_config.jeanmertz.rendered
  tags = [
    digitalocean_tag.jeanmertz.id,
    digitalocean_tag.production.id,
  ]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "${path.cwd}/check_health.sh ${self.ipv4_address}"
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  version    = "~> 1.4"
}

provider "tls" {
  version = "~> 2.1"
}

resource "acme_registration" "account" {
  account_key_pem = var.acme_private_key
  email_address   = var.email_address

  lifecycle {
    # If this resource is destroyed, the account is disabled by Let's Encrypt,
    # and the `acme_private_key` variable can no longer be used to generate a
    # new key.
    #
    # If this happens, you can generate a new key using:
    #
    #     $ openssl genrsa -out acme.pem 4096
    #
    # This will also generate new TLS certificates for the configured domains.
    prevent_destroy = true
  }
}

resource "tls_private_key" "domain" {
  for_each = var.domains

  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "domain" {
  for_each = var.domains

  key_algorithm   = tls_private_key.domain[each.key].algorithm
  private_key_pem = tls_private_key.domain[each.key].private_key_pem
  dns_names       = [each.key, "*.${each.key}"]

  subject {
    common_name  = each.key
    organization = each.value["organisation"]
    country      = "The Netherlands"
  }
}

resource "acme_certificate" "domain" {
  for_each = var.domains

  account_key_pem         = acme_registration.account.account_key_pem
  certificate_request_pem = tls_cert_request.domain[each.key].cert_request_pem

  dns_challenge {
    provider = "digitalocean"

    config = {
      DO_AUTH_TOKEN = var.digitalocean_token
    }
  }
}

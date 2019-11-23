provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  version    = "~> 1.4"
}

provider "tls" {
  version = "~> 2.1"
}

resource "tls_cert_request" "jeanmertz" {
  key_algorithm   = "ECDSA"
  private_key_pem = var.cert_private_key
  dns_names       = ["jeanmertz.com", "*.jeanmertz.com"]

  subject {
    common_name  = "jeanmertz.com"
    organization = "Jean Mertz"
    country      = "The Netherlands"
  }
}

resource "acme_registration" "jeanmertz" {
  account_key_pem = var.acme_private_key
  email_address   = var.email_address
}

resource "acme_certificate" "jeanmertz" {
  account_key_pem         = acme_registration.jeanmertz.account_key_pem
  certificate_request_pem = tls_cert_request.jeanmertz.cert_request_pem

  dns_challenge {
    provider = "digitalocean"

    config = {
      DO_AUTH_TOKEN = var.digitalocean_token
    }
  }
}

variable "acme_private_key" {
  type        = string
  description = "Private key used to authenticate with LetsEncrypt."
}

variable "acme_private_jwk" {
  type        = string
  description = "The LetsEncrypt private key in JWK format."
}

variable "cert_private_key" {
  type        = string
  description = "Private key used to create or update the LetsEncrypt TLS certificates."
}

variable "digitalocean_token" {
  type        = string
  description = "Token used to query the DigitalOcean API."
}

variable "email_address" {
  type        = string
  description = "Personal email address."
}

variable "ssh_public_key" {
  type        = string
  description = "Public key used to allow SSH access to the VM."
}

provider "http" {
  version = "~> 1.1"
}

data "http" "source_ip" {
  url = "https://ipv4.icanhazip.com"
}

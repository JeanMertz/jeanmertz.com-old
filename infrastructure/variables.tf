variable "acme_private_key" {
  type        = string
  description = "Private key used to authenticate with LetsEncrypt."
}

variable "digitalocean_token" {
  type        = string
  description = "Token used to query the DigitalOcean API."
}

variable "domains" {
  type        = map(object({ organisation = string, email_address = string }))
  description = "A map of domain keys with TLS certificate properties."
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

provider "ignition" {
  version = "~> 1.1"
}

data "ignition_config" "jeanmertz" {
  directories = [
    "${data.ignition_directory.www.id}",
  ]

  files = concat(
    [for k in data.ignition_file.cert_keys : k.id],
    [for c in data.ignition_file.cert_crts : c.id],
    [
      data.ignition_file.profile_variables.id,
      data.ignition_file.nginx_conf.id,
      data.ignition_file.sshd_config.id
    ],
  )

  systemd = [
    "${data.ignition_systemd_unit.container_webserver.id}",
    "${data.ignition_systemd_unit.sshd_port.id}",
  ]
}

data "ignition_directory" "www" {
  filesystem = "root"
  path       = "/opt/www/jeanmertz.com/public"
  mode       = 493 # 755
  uid        = 500
  gid        = 500
}

data "ignition_file" "profile_variables" {
  filesystem = "root"
  path       = "/etc/profile.d/variables.sh"
  mode       = 420 # 644

  content {
    content = <<-EOT
      export TERM=xterm
    EOT
  }
}

data "ignition_file" "cert_keys" {
  for_each = var.domains

  filesystem = "root"
  path       = "/opt/etc/certs/${each.key}.key"
  mode       = 384 # 600

  content {
    content = tls_private_key.domain[each.key].private_key_pem
  }
}

data "ignition_file" "cert_crts" {
  for_each = var.domains

  filesystem = "root"
  path       = "/opt/etc/certs/${each.key}.crt"
  mode       = 384 # 600

  content {
    content = acme_certificate.domain[each.key].certificate_pem
  }
}

data "ignition_file" "nginx_conf" {
  filesystem = "root"
  path       = "/opt/etc/nginx/nginx.conf"
  mode       = 420 # 644

  content {
    content = file("${path.cwd}/nginx.conf")
  }
}

data "ignition_file" "sshd_config" {
  filesystem = "root"
  path       = "/etc/ssh/sshd_config"
  mode       = 384 # 600

  content {
    content = file("${path.cwd}/sshd_config")
  }
}

data "ignition_systemd_unit" "container_webserver" {
  name    = "webserver.service"
  content = file("${path.cwd}/webserver.service")
}

data "ignition_systemd_unit" "sshd_port" {
  name = "sshd.socket"

  dropin {
    name    = "10-sshd-port.conf"
    content = file("${path.cwd}/sshd.socket")
  }
}

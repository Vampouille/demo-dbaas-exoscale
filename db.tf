module "netblocks" {
  source = "git::ssh://git@github.com/camptocamp/terraform-netblocks.git"
}

resource "random_string" "admin_password" {
  length  = 20
  special = false
}

resource "random_string" "user_password" {
  length  = 20
  special = false
}

provider "exoscale" {}

resource "exoscale_database" "this" {
  zone = "ch-dk-2"
  name = "meetup-db"
  type = "pg"
  plan = "business-8"

  maintenance_dow  = "monday"
  maintenance_time = "04:00:00"

  termination_protection = false

  pg {
    version         = "14"
    backup_schedule = "03:00"

    ip_filter = local.client_ips

    admin_username = "admin"
    admin_password = random_string.admin_password.result

    pg_settings = jsonencode({
      timezone : "Europe/Zurich"
    })
  }

  lifecycle {
    ignore_changes = [
      pg[0].admin_password,
      pg[0].admin_username,
    ]
  }
}

provider "postgresql" {
  scheme   = "postgres"
  host     = local.pg_infos.host
  port     = local.pg_infos.port
  database = local.pg_infos.database
  sslmode  = "require"
  username = local.pg_infos.username
  password = local.pg_infos.password

  expected_version = "14.3"

  superuser = false
}

resource "postgresql_role" "this" {
  name           = "user"
  login          = true
  password       = random_string.user_password.result
  skip_drop_role = true

  depends_on = [
    null_resource.wait_for_db
  ]
}

resource "postgresql_grant_role" "grant_root" {
  role              = local.pg_infos.username
  grant_role        = postgresql_role.this.name
  with_admin_option = true
}

resource "postgresql_database" "this" {
  name  = "test"
  owner = postgresql_role.this.name

  depends_on = [
    null_resource.wait_for_db,
    postgresql_role.this
  ]
}

resource "postgresql_extension" "this" {
  name     = "pg_stat_statements"
  database = local.pg_infos.database

  depends_on = [
    null_resource.wait_for_db
  ]
}

output "connection_uri" {
  value     = exoscale_database.this.uri
  sensitive = true
}

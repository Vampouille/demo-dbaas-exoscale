locals {
  client_ips = flatten([
    module.netblocks.camptocamp,
    "89.145.164.0/23",
    "91.92.202.0/23",
    "91.92.154.0/23",
    "159.100.245.0/24",
    "159.100.246.0/23",
    "159.100.248.0/21",
    "194.182.164.0/22",
    "194.182.188.0/22",
    "82.64.170.12/32",
  ])
  pg_infos = regex("postgres://(?P<username>[a-z]+):(?P<password>[^@]+)@(?P<host>[^:]+):(?P<port>[0-9]+)/(?P<database>[^\\?]+)\\?(?P<option>.+)", exoscale_database.this.uri)
  primary_uri = "postgresql://${local.pg_infos.username}:${local.pg_infos.password}@${local.pg_infos.host}:${local.pg_infos.port}/${local.pg_infos.database}?${local.pg_infos.option}"
  replica_uri = "postgresql://${local.pg_infos.username}:${local.pg_infos.password}@replica-${local.pg_infos.host}:${local.pg_infos.port}/${local.pg_infos.database}?${local.pg_infos.option}"
}

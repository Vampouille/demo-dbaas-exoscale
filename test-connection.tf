provider "docker" {
  #  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "postgres" {
  name         = "postgres:14"
  keep_locally = true
}

# Create a container
resource "docker_container" "psql" {
  image      = docker_image.postgres.latest
  name       = "psql"
  dns        = ["8.8.8.8"]
  tty        = true
  entrypoint = ["/bin/bash"]
  command    = []
  env = [
    "PGHOST=${local.pg_infos.host}",
    "PGPORT=${local.pg_infos.port}",
    "PGPASSWORD=${local.pg_infos.password}",
    "PGUSER=${local.pg_infos.username}",
    "PGDATABASE=${local.pg_infos.database}",
  ]
}

resource "local_sensitive_file" "foo" {
  content  = "${local.pg_infos.host}:${local.pg_infos.port}:${local.pg_infos.database}:${local.pg_infos.username}:${local.pg_infos.password}"
  filename = pathexpand("~/.pgpass")
}

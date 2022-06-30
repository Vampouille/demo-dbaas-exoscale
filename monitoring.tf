resource "docker_image" "exporter" {
  name         = "prometheuscommunity/postgres-exporter:v0.10.1"
  keep_locally = true
}

resource "docker_image" "prometheus" {
  name         = "quay.io/prometheus/prometheus:v2.36.2"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:8.5.6"
  keep_locally = true
}

resource "docker_network" "this" {
  name = "monitoring"
}

resource "docker_container" "exporter" {
  image = docker_image.exporter.latest
  name  = "exporter"
  dns   = ["8.8.8.8"]
  env = [
    "DATA_SOURCE_NAME=${replace(exoscale_database.this.uri, "postgres://", "postgresql://")}",
    "PG_EXPORTER_AUTO_DISCOVER_DATABASES=true",
    "PG_EXPORTER_EXTEND_QUERY_PATH=/mnt/queries.yaml",
    "PG_EXPORTER_EXCLUDE_DATABASES=_aiven,template0,template1"
  ]
  volumes {
    container_path = "/mnt/queries.yaml"
    host_path      = abspath("${path.module}/queries.yaml")
    read_only      = false
  }
  networks_advanced {
    name = docker_network.this.name
  }
}

resource "docker_container" "exporter-replica" {
  image = docker_image.exporter.latest
  name  = "exporter-replica"
  dns   = ["8.8.8.8"]
  env = [
    "DATA_SOURCE_NAME=${local.replica_uri}",
    "PG_EXPORTER_AUTO_DISCOVER_DATABASES=true",
    "PG_EXPORTER_EXTEND_QUERY_PATH=/mnt/queries.yaml",
    "PG_EXPORTER_EXCLUDE_DATABASES=_aiven,template0,template1"
  ]
  volumes {
    container_path = "/mnt/queries.yaml"
    host_path      = abspath("${path.module}/queries.yaml")
    read_only      = false
  }
  networks_advanced {
    name = docker_network.this.name
  }
}

resource "docker_volume" "prometheus" {
  name = "prometheus"
}

resource "docker_container" "prometheus" {
  image = docker_image.prometheus.latest
  name  = "prometheus"
  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = abspath("${path.module}/prometheus.yml")
    read_only      = true
  }
  volumes {
    container_path = "/etc/prometheus/rules.yml"
    host_path      = abspath("${path.module}/rules.yml")
    read_only      = true
  }
  volumes {
    container_path = "/prometheus"
    volume_name    = docker_volume.prometheus.name
    read_only      = false
  }
  networks_advanced {
    name = docker_network.this.name
  }
  ports {
    internal = 9090
    external = 9090
  }

}

resource "docker_volume" "grafana" {
  name = "grafana"
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.latest
  name  = "grafana"
  volumes {
    container_path = "/etc/grafana/provisioning/datasources/datasource.yaml"
    host_path      = abspath("${path.module}/grafana/datasource.yaml")
    read_only      = true
  }
  volumes {
    container_path = "/etc/grafana/provisioning/dashboards/dashboards.yaml"
    host_path      = abspath("${path.module}/grafana/dashboards.yaml")
    read_only      = true
  }
  volumes {
    container_path = "/var/lib/grafana/dashboards/dashboard.json"
    host_path      = abspath("${path.module}/grafana/dashboard.json")
    read_only      = true
  }
  volumes {
    container_path = "/var/lib/grafana"
    volume_name    = docker_volume.grafana.name
    read_only      = false
  }
  networks_advanced {
    name = docker_network.this.name
  }
  ports {
    internal = 3000
    external = 3000
  }

}

resource "docker_container" "traffic" {
  image   = docker_image.postgres.latest
  name    = "traffic"
  command = ["/usr/local/bin/traffic.sh"]
  dns     = ["8.8.8.8"]
  env = [
    "PGHOST=${local.pg_infos.host}",
    "PGPORT=${local.pg_infos.port}",
    "PGUSER=${local.pg_infos.username}",
    "PGPASSWORD=${local.pg_infos.password}",
    "PGDATABASE=${local.pg_infos.database}",
  ]
  volumes {
    container_path = "/usr/local/bin/traffic.sh"
    host_path      = abspath("${path.module}/traffic.sh")
    read_only      = true
  }
  networks_advanced {
    name = docker_network.this.name
  }
}

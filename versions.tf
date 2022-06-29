terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.33"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.16.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.17.0"
    }
  }
}

resource "null_resource" "wait_for_db" {
  triggers = {
    db_state = exoscale_database.this.state
  }

  provisioner "local-exec" {
    command = <<EOT
    for i in `seq 1 60`; do
      if psql $DB_URI; then
        exit 0
      else
        sleep 5
      fi
    done
    echo TIMEOUT
    exit 1
    EOT

    environment = {
      DB_URI = exoscale_database.this.uri
    }
  }
}

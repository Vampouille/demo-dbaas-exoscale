#!/bin/bash

while [ $(pg_isready -q; echo $?) != 0 ]; do
  echo "Waiting for cluster to start..."
  sleep 1
done

psql <<OES
SELECT 'CREATE DATABASE organisme'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'organisme')\gexec

\c organisme

CREATE TABLE IF NOT EXISTS data(
  id   serial,
  data int
);

INSERT INTO data (data) SELECT g.id FROM generate_series(1, 50000) AS g (id);
INSERT INTO data (data) SELECT g.id FROM generate_series(1, 50000) AS g (id);
INSERT INTO data (data) SELECT g.id FROM generate_series(1, 50000) AS g (id);

UPDATE data SET data = data + 1 WHERE id % 10 <> 1;

SELECT 'CREATE DATABASE animaux'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'animaux')\gexec
\c animaux

CREATE TABLE IF NOT EXISTS animal(
  id   serial,
  nom  text
);
OES

pgbench -i -I dtGvp --foreign-keys -s 10

while [ true ]; do
  pgbench --no-vacuum -T 10 -c 10
  sleep 3.2
  psql -c 'INSERT INTO data (data) SELECT g.id FROM generate_series(1, 50000) AS g (id)' organisme
  psql -c 'BEGIN; INSERT INTO data (data) SELECT g.id FROM generate_series(1, 50000) AS g (id); SELECT pg_sleep(10); COMMIT;' organisme
  echo "OK"
done

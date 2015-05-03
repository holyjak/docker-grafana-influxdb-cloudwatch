#!/bin/bash

if [ ! -d /var/easydeploy/share/db ]; then
  echo "No .../db, likely a freshly mounted Volume, copying initial InfluxDB data"
  cp -rT /var/infuxdb_initial_data_backup /var/easydeploy/share
else
  echo "InfluxDB seems to be set up, skipping copying of data"
fi

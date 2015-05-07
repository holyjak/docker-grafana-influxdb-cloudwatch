docker-grafana-influxdb-cloudwatch
==================================

Derived from [kamon-io/docker-grafana-influxdb][1],
this image contains a sensible default configuration of InfluxDB and Grafana but also:

   * Is based on [phusion/baseimage](http://phusion.github.io/baseimage-docker/) instead of stock
     Ubuntu
   * Bundles [cloudwatch-to-graphite](https://github.com/crccheck/cloudwatch-to-graphite), run via
     cron, for fetching metrics from AWS CloudWatch
   * Enables InfluxDB's Graphite input plugin

See the introductory blog post [All-in-one Docker with Grafana, InfluxDB, and cloudwatch-to-graphite for AWS/Beanstalk monitoring](https://theholyjava.wordpress.com/2015/05/07/all-in-one-docker-with-grafana-influxdb-and-cloudwatch-to-graphite-for-awsbeanstalk-monitoring/) for more details.

### Configuration

For InfluxDB and Grafana, see [docker-grafana-influxdb][1].
By default there are 2 databases, `grafana` for dashboards and `data` for metrics.
Use the user and password `data` to access the metrics via the InfluxDB UI.

Regarding cloudwatch-to-graphite and its `leadbutt` command-line:

  * Metrics to fetch are in [`cloudwatch/leadbutt-cloudwatch`](cloudwatch/leadbutt-cloudwatch)
  * AWS Credentials are supposed to be provided via env variables, for example:
    `docker run -e AWS_ACCESS_KEY_ID=xxxx -e AWS_SECRET_ACCESS_KEY=yyyy ...` (see `./start`) - in the case of AWS Elastic Beanstalk you can set them in you environment's configuration UI

### Other

See `utils/leadbutt2influxdb.clj` for a utility that can convert leadbutt output
to InfluxDB input. You might want to copy and modify the leadbutt configuration
file to fetch the last 2 weeks of hourly data (`Period: 60; Count: 336`), use
the utility to convert it and post to InfluxDB.

[1]: https://github.com/kamon-io/docker-grafana-influxdb

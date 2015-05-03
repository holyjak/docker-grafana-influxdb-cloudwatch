FROM phusion/baseimage:0.9.16

# TODO Update Grafana to 2.0.2; consider using .deb installer?
ENV GRAFANA_VERSION 1.9.1
ENV INFLUXDB_VERSION 0.8.8

# Prevent some error messages
ENV DEBIAN_FRONTEND noninteractive

#RUN		echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list
RUN		apt-get -y update && apt-get -y upgrade

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN 	apt-get -y install wget nginx-light curl

# Install Grafana to /src/grafana
RUN		mkdir -p src/grafana && cd src/grafana && \
			wget http://grafanarel.s3.amazonaws.com/grafana-${GRAFANA_VERSION}.tar.gz -O grafana.tar.gz && \
			tar xzf grafana.tar.gz --strip-components=1 && rm grafana.tar.gz

# Install InfluxDB
RUN		wget http://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
			dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/config.toml /etc/influxdb/config.toml
ADD		influxdb/run.sh /etc/service/influxdb/run
# These two databases have to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV		PRE_CREATE_DB data grafana
ENV		INFLUXDB_DATA_USER data
ENV		INFLUXDB_DATA_PW data
ENV		INFLUXDB_GRAFANA_USER grafana
ENV		INFLUXDB_GRAFANA_PW grafana
ENV		ROOT_PW root

# Configure Grafana
ADD		./grafana/config.js /src/grafana/config.js
#ADD	./grafana/scripted.json /src/grafana/app/dashboards/default.json

ADD		./configure.sh /configure.sh
ADD		./set_grafana.sh /set_grafana.sh
ADD		./set_influxdb.sh /set_influxdb.sh
RUN 	/configure.sh

# Configure nginx (that serves Grafana)
ADD		./nginx/run.sh /etc/service/nginx/run
ADD		./nginx/nginx.conf /etc/nginx/nginx.conf


# -------------- #
#   CloudWatch   #
# -------------- #

# Add a script run automatically at startup that creates /docker.env
# so that the Cron job can access the AWS credentials env variables
ADD cloudwatch/env2file /etc/my_init.d/env2file

RUN apt-get -y install python-pip

RUN pip install --global-option="--without-libyaml" PyYAML
# ^- libyaml seems to be unavailable here; cloudwatch dependency
RUN pip install cloudwatch-to-graphite==0.5.0

ADD cloudwatch/leadbutt-cloudwatch.conf /etc/leadbutt-cloudwatch.conf
ADD cloudwatch/leadbutt-cloudwatch-cron.conf /etc/cron.d/leadbutt-cloudwatch
# TODO(improvement) use crontab fragments in /etc/cron.d/ instead of using root's crontab
#                     See for other tips: http://stackoverflow.com/questions/26822067/running-cron-python-jobs-within-docker
RUN crontab /etc/cron.d/leadbutt-cloudwatch

# Note: AWS cedentials should be provided via ENV vars; ex.:
#     docker run -e AWS_ACCESS_KEY_ID=xxxx -e AWS_SECRET_ACCESS_KEY=yyyy ...

# ----------- #
#   Cleanup   #
# ----------- #

RUN		apt-get autoremove -y wget curl && \
			apt-get -y clean && \
			rm -rf /var/lib/apt/lists/* && rm /*.sh

# ----------- #
#   Volumes   #
# ----------- #

ADD configure_influxdb_at_run.sh /etc/my_init.d/configure_influxdb_at_run.sh
RUN cp -r /var/easydeploy/share /var/infuxdb_initial_data_backup
# influxdb data dir:
VOLUME ["/var/easydeploy/share"]

# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	80

# InfluxDB Admin server
EXPOSE	8083

# InfluxDB HTTP API
EXPOSE	8086

# InfluxDB HTTPS API
EXPOSE	8084

# -------- #
#   Run!   #
# -------- #
CMD /sbin/my_init

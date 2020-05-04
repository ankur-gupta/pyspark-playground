#!/usr/bin/env bash

# SPARK_HOME is defined in the Dockerfile (typical value "/usr/local/spark")
# SPARK_MASTER_HOST and SPARK_MASTER_PORT are defined in the docker-compose.yml
# with typical values SPARK_MASTER_HOST=spark-master, SPARK_MASTER_PORT=7077.
"${SPARK_HOME}"/sbin/start-slave.sh \
  "spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"

# Based on https://stackoverflow.com/questions/45461263/how-can-i-keep-docker-container-running
echo "Tailing just to not have the container exit"
tail -f /dev/null

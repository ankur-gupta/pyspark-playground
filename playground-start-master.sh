#!/usr/bin/env bash

# Start spark server
# SPARK_HOME is defined in the Dockerfile (typical value "/usr/local/spark")
"${SPARK_HOME}"/sbin/start-master.sh

# We will symlink /data to $HOME/data
ln -s /data $HOME/data

# Start jupyter notebook
# FIXME: Do I need the ability to start a jupyter notebook separately from the spark cluster?
jupyter notebook --ip "${JUPYTER_HOST_IP}" --port "${JUPYTER_PORT}"

# # Based on https://stackoverflow.com/questions/45461263/how-can-i-keep-docker-container-running
# We don't need this for spark-master because jupyter container runs until close anyways.
# echo "Tailing just to not have the container exit"
# tail -f /dev/null

#!/usr/bin/env bash

# Start spark server
# SPARK_HOME is defined in the Dockerfile (typical value "/usr/local/spark")
"${SPARK_HOME}"/sbin/start-master.sh

# Start jupyter notebook
# FIXME: Create a jupyter config
# FIXME: Do I need the ability to start a jupyter notebook separately from the spark cluster?
jupyter notebook --ip 0.0.0.0 --port "${JUPYTER_PORT}"

# # Based on https://stackoverflow.com/questions/45461263/how-can-i-keep-docker-container-running
# echo "Tailing just to not have the container exit"
# tail -f /dev/null

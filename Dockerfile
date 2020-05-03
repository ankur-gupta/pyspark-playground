FROM ubuntu:bionic

# This is the user that will execute most of the commands within the docker
# container.
ARG PLAYGROUND_USER="neo"
ARG PLAYGROUND_USER_PASSWORD="agentsmith"

# Install the things that need root access first.
USER root

# Install Java 8. Note Java 9+ is not compatible with Spark 2.4.+.
# See https://stackoverflow.com/questions/51330840/why-apache-spark-does-not-work-with-java-10-we-get-illegal-reflective-then-java
# We clean up apt cache to reduce image size as mentioned here:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
RUN apt-get update \
    && apt-get install -y \
        sudo \
        unzip \
        nano \
        wget \
        man \
        tree \
        vim-tiny \
        iputils-ping \
        ssh \
        openjdk-8-jdk \
        python3 \
        python3-dev \
        python3-pip \
 && rm -rf /var/lib/apt/lists/*

# Print Python and Java version
RUN echo java -version
RUN echo python3 --version

# Download spark tarball from the preferred mirror and install it in
# /usr/local/spark. This will be the only copy of spark (or pyspark) that
# we have. We won't install pyspark using `pip3`. Instead, we will update
# PYTHONPATH to get pyspark from /usr/local/spark/python.
# This line is adapted from https://registry.hub.docker.com/r/jupyter/pyspark-notebook/dockerfile.
# See Modified BSD License at https://github.com/jupyter/docker-stacks/blob/master/LICENSE.md.
ENV APACHE_SPARK_VERSION=2.4.5 \
    HADOOP_VERSION=2.7
RUN cd /tmp && \
    wget -q $(wget -qO- https://www.apache.org/dyn/closer.lua/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz\?as_json | \
    python3 -c "import sys, json; content=json.load(sys.stdin); print(content['preferred']+content['path_info'])") && \
    echo "2426a20c548bdfc07df288cd1d18d1da6b3189d0b78dee76fa034c52a4e02895f0ad460720c526f163ba63a17efae4764c46a1cd8f9b04c60f9937a554db85d2 *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# Spark/PySpark configuration. Update both PYTHONPATH and PATH to get
# easy access to all the executables.
ENV SPARK_HOME=/usr/local/spark
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip \
#    SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH=$PATH:$SPARK_HOME/bin

# We don't have `python` executable. Since some spark scripts have hardcoded
# `python`, we will symlink a `python` but we aim to use the symlinked
# `python` sparingly.
RUN cd /usr/bin && ln -s /usr/bin/python3 /usr/bin/python

# Set the default values
ENV PYSPARK_PYTHON=/usr/bin/python \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python

# Create $PLAYGROUND_USER non-interactively and add it to sudo group.
# See
# (1) https://stackoverflow.com/questions/25845538/how-to-use-sudo-inside-a-docker-container
# (2) https://askubuntu.com/questions/7477/how-can-i-add-a-new-user-as-sudoer-using-the-command-line
RUN useradd -m $PLAYGROUND_USER \
    && adduser $PLAYGROUND_USER sudo \
    && echo $PLAYGROUND_USER:$PLAYGROUND_USER_PASSWORD | chpasswd

# We will setup environment variables and python packages for the
# $PLAYGROUND_USER instead of root.
USER $PLAYGROUND_USER

# Note that there is no `pip` executable; use `pip3`.
# Install the common packages we may need. Don't install pyspark using pip3
# because we installed it from source already. We should be able to install
# more packages by running `pip3 install --user <package-name>` within the
# container later on, if needed.
RUN pip3 install --user \
    numpy \
    pandas \
    six \
    ipython \
    jupyter \
    matplotlib \
    seaborn \
    scipy \
    scikit-learn

# Augment path so we can call ipython and jupyter
ENV PATH=$PATH:/home/$PLAYGROUND_USER/.local/bin

# Set the working directory as the home directory of $PLAYGROUND_USER
WORKDIR /home/$PLAYGROUND_USER


# from pyspark.sql import SparkSession
# spark = SparkSession.builder.appName('my_app').getOrCreate()
# df = spark.createDataFrame([(_, _) for _ in range(1000)], 'x INT, y INT')

# docker build . -t pyspark-playground
# docker run -it -p 8888:8888 --network my-temp-network pyspark-playground /bin/bash
# jupyter notebook --ip 0.0.0.0 --port 8888 --allow-root

# FIXME: Add tini or you'll have PID starvation.

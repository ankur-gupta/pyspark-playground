FROM ubuntu:bionic

# Install Java 8. Note Java 9+ is not compatible with Spark 2.4.+.
# See https://stackoverflow.com/questions/51330840/why-apache-spark-does-not-work-with-java-10-we-get-illegal-reflective-then-java
RUN apt-get update \
    && apt-get install -y \
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
        python3-pip

# Print Python and Java version
RUN echo java -version
RUN echo python3 --version

# Install the packages we will need. Don't install pyspark using pip3 because
# we will install from source so we can get other scripts.
RUN pip3 install --user numpy pandas six ipython jupyter

# Augment path so we can call ipython and jupyter
# Note that there is no `python` or `pip` executable. Use `python3` and `pip3`.
ENV PATH=$PATH:/root/.local/bin

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

# These are important because we don't have `python` executable.
ENV PYSPARK_PYTHON=/usr/bin/python3 \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python3


# from pyspark.sql import SparkSession
# spark = SparkSession.builder.appName('my_app').getOrCreate()
# df = spark.createDataFrame([(_, _) for _ in range(1000)], 'x INT, y INT')

# docker build . -t pyspark-playground
# docker run -it pyspark-playground /bin/bash

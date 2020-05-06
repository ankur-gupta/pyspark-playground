## PySpark Playground
This repository sets up a "scalable" pyspark cluster using docker compose.
This repository is intended for learning and experimentation only. It should
**NOT** be used any production work.

For example, this repository creates a user inside the container that has
`sudo` privileges and whose credentials (username/password) hardcoded in the
Dockerfile. This gets worse because the network setup by docker compose
allows unhindered interaction with public internet.

Such a design is usually not suitable for any production work. But this
helps avoid unnecessary friction when experimenting with pyspark.

If you need a pyspark docker container more suitable for production,
consider the official jupyter
[pyspark-notebook](https://registry.hub.docker.com/r/jupyter/pyspark-notebook/dockerfile).

## Features
This repository contains both a `Dockerfile` and a `docker-compose.yml` file.
The `docker-compose.yml` file depends on `Dockerfile`. See the instructions
below to install and run either of them.

### `Dockerfile`
`Dockerfile` that builds an image with the following already installed:
* Ubuntu 18.04.4 LTS Bionic Beaver (exact version of Ubuntu may change later)
* Java 8
* Python 3.6 (this could be upgraded to 3.7+ later)
* `pip3`
* tini
* spark and pyspark
* jupyter and ipython
* basic python packages such as numpy, pandas, matplotlib, scikit-learn, scipy and others

#### User
This image creates a `sudo`-privileged user for you. You should be able to
do everything (including installing packages using `apt-get`) as this user
without having to become `root`.

| Username | `neo`        |
|----------|--------------|
| Password | `agentsmith` |

#### Jupyter notebook
By default, running a container from this image would run a jupyter notebook
at port `8888`. The port `8888` is not exposed in the `Dockerfile` you can
expose it and bind it to a port on host machine via command line.

If you run a container based on this image without using
the `docker-compose.yml`, then a spark cluster won't be started for you but
you can start you own spark cluster either via command-line or via python
code within the jupyter notebook.

#### Why such a big linux image?
We use a bigger Linux base image and even install some more tools such as
`vim` because this is intended to make learning and experimentation
frictionless. We don't want to have to rebuild the image every time we need
a new package in a container that's running our experiments. The downside is that
the finally built image is huge, which is considered an acceptable tradeoff.

To ward off long building times, we clear both `apt-get` cache and `pip3` cache
properly so that most (if not all) layers are "docker cacheable". This means that
only the first docker build is slow and subsequent builds are fast.

### `docker-compose.yml`
This file sets up a pyspark cluster with these specifications:
* a separate docker network for the spark cluster
* a spark master container that runs the spark driver
* one or more spark slave containers that run spark workers

When you run `docker-compose`, the spark cluster is started for you and
a jupyter notebook runs on port `8888`. Any pyspark code you write in the
jupyter notebook simply needs to "attach" to the running spark cluster.

#### `data/` mount
This repository contains a
[`data`](https://github.com/ankur-gupta/pyspark-playground/tree/master/data)
folder with a sample juyter notebook. This folder gets mounted inside the
container as `$HOME/data`. Any files you create inside the container within
the mounted `$HOME/data` folder will be saved on your host machine's
`$REPO_ROOT/data` folder. So, when you exit the cluster you won't lose any
saved files. However, you should manually check (using another terminal window
or using the host machine's file manager) that you have all the files you
care about in your host machine before shutting down docker compose. You can
always download your jupyter notebook using jupyter's web UI.

## Installation
This repository have been tested with these versions. The versions are
important because we use some of the newer features of Docker Compose in this
repository which may not be available with older versions.

| Name                       | Version |
|----------------------------|---------|
| Docker Desktop (Community) | 2.2.0.5 |
| Docker Engine              | 19.03.8 |
| Docker Compose             | 1.25.4  |

See [Docker Compose versions](https://docs.docker.com/compose/compose-file/compose-versioning/) to see
if the version used in your `docker-compose.yml` is compatible with your
docker installation.

### Steps
1. **Install or update docker**. Docker from the
[official website](https://docs.docker.com/get-docker/) works well. Please
update your docker because because we use some of the newer features of
Docker Compose in this repository which may not be available with older
versions.
2. **Clone the repository**
    ```bash
    git clone git@github.com:ankur-gupta/pyspark-playground.git
    ```
3. **Build the image first**
    ```bash
   cd $REPO_ROOT
   docker build . -t pyspark-playground
    ```
   Building the image will take a long time for the first time but repeated builds
   (after minor edits to `Dockerfile`) should be quick because every layer
   gets cached.

   Check that the docker image was built successfully
   ```bash
   docker images pyspark-playground
   # REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
   # pyspark-playground   latest              e0fb4dc1dd23        13 hours ago        1.44GB
   ```

   The name `pyspark-playground` is important. If you have an existing docker
   image with the same name, the above command will overwrite it.
   But, more importantly, this name is hardcoded in `docker-compose.yml`. The
   benefit of hardcoding (instead of using something like `build: ./`) is that
   the image won't be rebuilt every time you run `docker-compose`.

4. **Test the image**
   ```bash
   # On your host machine
   docker run -it -p 8888:8888 pyspark-playground
   # ...
   # http://127.0.0.1:8888/?token=s0m3a1phanum3rict0k3n
   ```
   Use your browser to go to the address printed in terminal. You should be
   able to run python code in the jupyter notebook. You should also be able
   to create a one-container spark cluster from inside the jupyter notebook.
   If you want to create a spark cluster over multiple containers, continue
   to the next steps after exiting the container.

   Exit the container by pressing `Control+C` in the
   terminal. Exiting is important because the above command binds host
   machine's port `8888` and as long as this container is running you won't be
   able to bind anything else on the same port. For the next steps to work,
   you must exit the container and ensure that host machine's port `8888` is
   available. See **Troubleshooting** section below if you see an error related
   to ports.

   (Optional) If you don't want to run the jupyter notebook, you can specify a
   command at the end. For example, this won't run the jupyter notebook:
   ```bash
   # On your host machine
   docker run -it pyspark-playground /bin/bash
   # To run a command as administrator (user "root"), use "sudo <command>".
   # See "man sudo_root" for details.
   # neo@db6739ba2186:~$
   ```

5. **Create a spark cluster using docker compose**
   ```bash
   # Create 1 spark master and 2 spark slave containers.
   # You increase `2` to something more or you can omit the
   # `--scale spark-worker=2` part completely.
   cd $REPO_ROOT
   docker-compose up --scale spark-worker=2
   # Creating network "spark-network" with driver "bridge"
   # Creating spark-master ... done
   # Creating pyspark-playground_spark-worker_1 ... done
   # Creating pyspark-playground_spark-worker_2 ... done
   # Attaching to spark-master, pyspark-playground_spark-worker_1, pyspark-playground_spark-worker_2
   # ...
   # spark-master    |      or http://127.0.0.1:8888/?token=s0m3a1phanum3rict0k3n
   ```
   Use your browser to go to the address printed in terminal. You should
   see an already mounted folder called `data` in your jupyter web UI.
   Go to `data/spark-demo.ipynb` which contains some starter code to attach
   your pyspark session to the already running spark cluster. Try running the
   code. You can click on the URLs shown in the `data/spark-demo.ipynb`
   notebook for various spark web UIs.

6. (Optional) **Run bash within spark master**. Sometimes you want to access spark master to
   do other things such as call `ps` to check up on cluster or jupyter. You may also want to
   run `ipython` separately, in addition to the jupyter notebook that's already running.
   This can be done easily as follows. Keep the `docker-compose` running and in a new terminal,
   type:
   ```bash
   # The spark master container's name is spark-master (see docker-compose.yml)
   # Run on host machine's terminal:
   docker exec -it spark-master /bin/bash
   # To run a command as administrator (user "root"), use "sudo <command>".
   # See "man sudo_root" for details.
   # neo@spark-master:~$
   ```
   You're now inside the `spark-master` container. The spark cluster should already be running.
   You can check up on it like this.
   ```bash
   neo@spark-master:~$ ps aux | grep "java"
   # neo         14  0.4  8.7 4093396 178080 ?      Sl   20:34   0:04 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java -cp /usr/local/spark/conf/:/usr/local/spark/jars/* -Xmx1g org.apache.spark.deploy.master.Master --host spark-master --port 7077 --webui-port 8080
   # neo        209  0.0  0.0  11464   960 pts/1    S+   20:49   0:00 grep --color=auto java
   ```
   You can run any command here including `ipython`. This will be completely
   separate from the jupyter notebook that's already running. Since spark cluster
   if already running you just need to attach your ipython's pyspark to it (only
   if you want to run pyspark within ipython).
   ```bash
   neo@spark-master:~$ ipython
   # ...
   # In [1]: import os
   # ...: from pyspark.sql import SparkSession
   # ...: spark_master = 'spark://{}:{}'.format(os.environ['SPARK_MASTER_HOST'],
   # ...:                                       os.environ['SPARK_MASTER_PORT'])
   # ...: spark = (SparkSession.builder
   # ...:          .master(spark_master)
   # ...:          .appName('my_app')
   # ...:          .getOrCreate())
   # ...: df = spark.createDataFrame([(_, _) for _ in range(1000)], 'x INT, y INT')
   # ...: df.show()
   # ...
   # +---+---+
   # |  x|  y|
   # +---+---+
   # |  0|  0|
   # |  1|  1|
   # ...
   # | 19| 19|
   # +---+---+
   # only showing top 20 rows
   ```
   Press Control+C to exit this session without affecting the docker-compose
   that is running in the previous terminal.

7. **Shutdown docker compose.**
   Please make sure that you have all the files you care about on your host
   machine before you shut down. Shutting down docker compose is important
   because you don't want unnecessary networks or containers running on
   your machine. Proper shutdown is necessary to create a new cluster.
   ```bash
   # ...
   # spark-master    |      or http://127.0.0.1:8888/?token=s0m3a1phanum3rict0k3n
   # ...

   # Press Control+C twice, if needed.
   # Stopping pyspark-playground_spark-worker_1 ... done
   # Stopping pyspark-playground_spark-worker_2 ... done
   # Stopping spark-master                      ... done

   # Once you get back your host machine's terminal, execute this in the
   # $REPO_ROOT:
   docker-compose down
   # Removing pyspark-playground_spark-worker_1 ... done
   # Removing pyspark-playground_spark-worker_2 ... done
   # Removing spark-master                      ... done
   # Removing network spark-network
   ```
   This ensures that all the host machine's ports that were bound to the
   cluster are released and all docker containers and network(s) are
   destroyed. This frees up ports and namespace for any future runs of the
   same docker containers/networks or even different ones.

## Known issues
There are a few known issues. Some of these may be fixed in the future while
others are side effects of the design choices and those won't get "fixed".

### Hardcoding of ports and names
The ports, container names, and network names are "hardcoded" in
`docker-compose.yml`. Removing this hardcoding would introduce unnecessary
complexity that would be overkill for our use-case.

### Not idempotent
The ports and docker names in this repository are hardcoded. For now,
removing the hardcoding seems difficult and is not worth it for our use case.
This means that running `docker-compsose` twice without shutting it down
properly might have unexpected behavior. This also means that if for some
reason you have other unrelated docker containers/networks that have the
same name as the ones used in this repository, you may have conflicts.
The same applies to ports on the host machine.

### Why is there no `https://` ?
Both jupyter notebook and spark serve web pages. These web pages are served
on `http://` instead of `https://`', by default. For jupyter, this can be
fixed as shown in
[pyspark-notebook](https://github.com/jupyter/docker-stacks/blob/master/base-notebook/jupyter_notebook_config.py#L18)
but this hasn't been implemented yet. For spark web UIs, this is more
difficult as mentioned
[here](https://stackoverflow.com/questions/44936756/how-to-configure-spark-standalones-web-ui-for-https).
Spark 3.0 is in around the corner and we'll wait until that becomes mainstream
before we try and fix this issue ourselves. See `$REPO_ROOT/index.html` for a handy list
of all posssible URLs.

### Worker web UI cannot be accessed?
This is a design choice. Since we want the cluster specified in
`docker-compose` to be "scalable" in the number of spark slave containers,
we cannot bind the same port `8081` on the host machine to multiple
worker web UIs. Looking at the worker web UI is a less often required
feature.

## Troubleshooting
### Port `8888` already allocated
You cannot run multiple web servers
(such as jupyter notebooks) on the same host machine port. When you try to
run the second web server on the same port, you see an error like this:
```bash
docker: Error response from daemon: driver failed programming external
connectivity on endpoint loving_tu (bc2a23b1ca0a494537075e9aba2fcb00a7f3d63ff958984fbd3c76b1b9212404):
Bind for 0.0.0.0:8888 failed: port is already allocated.
```
These are some common scenarios when this happens while using this
repository:
* you have a jupyter notebook already running on the host machine directly
  that is serving on the port `8888`
* you have two containers running off the `pyspark-playground` image
  (may be you ran `docker run -it -p 8888:8888 pyspark-playground` twice)
* you forgot to exit the container as mentioned in the **Test the image**
  step above and you're trying to run `docker-compose`

### Unsupported version in `docker-compose.yml`
This error indicates that the docker installation you have does not support the version
specified in `docker-compose.yml`. Consider updating your docker installation first.
It may not be possible to decrease the version specified in `docker-compose.yml` because
of the newer features it uses.
```
ERROR: Version in "./docker-compose.yml" is unsupported. You might be seeing this error because you're using the wrong Compose file version. Either specify a supported version (e.g "2.2" or "3.3") and place your service definitions under the `services` key, or omit the `version` key and place your service definitions at the root of the file to use version 1.
For more on the Compose file format versions, see https://docs.docker.com/compose/compose-file/
```

## References
This repository was made with the help of a lot of resources. We thank all of
them here.

### Jupyter Docker Stacks
Jupyter has lots of notebooks available for you to use directly without having
to git clone anything at all. These notebooks are more suited towards
production use, though you still want to get them approved from your company's
security team first.

* [Official Documentation](https://jupyter-docker-stacks.readthedocs.io/en/latest/index.html)
* [GitHub repository](https://github.com/jupyter/docker-stacks)
* Dockerfiles for a hierarchy of images
    * [pyspark-notebook](https://registry.hub.docker.com/r/jupyter/pyspark-notebook/dockerfile)
    * [scipy-notebook](https://registry.hub.docker.com/r/jupyter/scipy-notebook/dockerfile)
    * [minimal-notebook](https://registry.hub.docker.com/r/jupyter/minimal-notebook/dockerfile)
    * [base-notebook](https://registry.hub.docker.com/r/jupyter/base-notebook/dockerfile)
* tini
    * [What is advantage of Tini?](https://github.com/krallin/tini/issues/8)
    * Setup tini [for jupyter notebook](https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#docker-cmd) insider docker

### Blog posts
We are thankful to the excellent blog posts here.
* [A Journey Into Big Data with Apache Spark: Part 1 - Towards Data Science](https://towardsdatascience.com/a-journey-into-big-data-with-apache-spark-part-1-5dfcc2bccdd2)
* [A Journey Into Big Data with Apache Spark — Part 2 - Towards Data Science](https://towardsdatascience.com/a-journey-into-big-data-with-apache-spark-part-2-4511aa19a900)
* [How to Put Jupyter Notebooks in a Dockerfile](https://u.group/thinking/how-to-put-jupyter-notebooks-in-a-dockerfile/)
* [Running PySpark and Jupyter using Docker - K2 Data Science & Engineering](https://blog.k2datascience.com/running-pyspark-with-jupyter-using-docker-61ca0aa7da6b)
* [Using Docker and PySpark - Level Up Coding](https://levelup.gitconnected.com/using-docker-and-pyspark-134cd4cab867)

### Docker tips
1. Define `ENV` variables for any user. All users have access to it.
This has been verified in this repository and this
[post](https://stackoverflow.com/questions/32574429/dockerfile-create-env-variable-that-a-user-can-see)
also says the same thing.

2. Handy table for [Docker Compose versions](https://docs.docker.com/compose/compose-file/compose-versioning/).

3. [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/)
has documentation for every keyword used within `docker-compose.yml`.

3. [Networking in Compose](https://docs.docker.com/compose/networking/) says
that, by default, Docker Compose sets up a single network for the entire app
represented by a `docker-compose.yml` file, by default. Each container for a
service is discoverable by other containers on that network at a name identical
to the container name.

4. IPAM is just [IP address management](https://en.wikipedia.org/wiki/IP_address_management).

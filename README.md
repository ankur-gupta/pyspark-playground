`docker-compose up --scale spark-worker=2`

## Tested with
| Name                       | Version |
|----------------------------|---------|
| Docker Desktop (Community) | 2.2.0.5 |
| Docker Engine              | 19.03.8 |
| Docker Compose             | 1.25.4  |

## Links
1. Define `ENV` variables for any user. All users have access to it.
This has been verified in this repository and this
[post](https://stackoverflow.com/questions/32574429/dockerfile-create-env-variable-that-a-user-can-see)
also says the same thing.

2. Handy table for [Docker Compose versions](https://docs.docker.com/compose/compose-file/compose-versioning/).
This webpage also has documentation for every keyword.

3. [Networking in Compose](https://docs.docker.com/compose/networking/) says
that, by default, Docker Compose sets up a single network for the entire app
represented by a `docker-compose.yml` file, by default. Each container for a
service is discoverable by other containers on that network at a name identical
to the container name.

4. IPAM is just [IP address management](https://en.wikipedia.org/wiki/IP_address_management).


## References
1. [How to Put Jupyter Notebooks in a Dockerfile](https://u.group/thinking/how-to-put-jupyter-notebooks-in-a-dockerfile/)

* The path to the foodie db in Docker needs to be set correctly.
  
  Working solution:
  - Supply environment variables to Docker deployment via `deployment.env`
  - Reference with 
    ```yaml 
    env_file:
      - deployment.env
    ```
    in the `docker-compose.yml` for the service that uses the database.
  - Set database address to `jdbc:postgresql://<db-service-name>:<port>/<database>`,
    e.g. `jdbc:postgresql://db:5432/foodie`.
    The name of the service is the entry in the `services` array in the `docker-compose.yml`.
    The database parameters `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` are defined via the environment variables set in `db.env`,
    and then referenced in database service.
    - If you want to change the port that Docker uses, add `command: -p <new-port>`
      to the database container configuration in the `docker-compose.yml`,
      and reference the new port in the address above.
    - The default port is `5432`.
      It is likely that it's fine to use the default port,
      because every project runs on a different Docker network.
  - There seems to be no need for
    - exposing a port
      ```yaml
      expose:
        - <port1>
        ...
        - <portN>
      ```
    - port mapping
      ```yaml
      ports:
        - "<mapped-to-1>:<mapped-from-1>"
        ...
        - "<mapped-to-N>:<mapped-from-N>"
      ```
    because there is no need to connect to the database externally (at least in the current setup).
* `sudo /home/nda/.sdkman/candidates/sbt/current/bin/sbt "Docker / publishLocal"`
  creates a correct local image, which can be fetched with `foodie:latest`
* Docker configuration may need some adjustments in `build.sbt`
  - Either set everything so the publishing pushes to DockerHub
  - or configure correct build steps, build, and publish manually
* `deployment.env` should most likely not be committed
* Working solution for application externalisation:
  - The default port for the application is `9000` via Play
  - Add a port mapping for the backend service in the `docker-compose.yml`, 
    and map the port where necessary.
    ```yaml
    ports:
    - "<target-port>:9000"
    ```
    N.B.: The ports that are mapped to are actual system ports.
    If multiple Play services run on the same system, the chosen ports need to be all different.
    After running `docker compose up` the service is reachable via `localhost:<target-port>`. 
  - The default port can be changed via the start parameter
    `-Dhttp.port=<application-port>`.
    This parameter can be passed to the application via the `Dockerfile`.
    The value can be defined in `build.sbt` via `dockerCmd ++= Seq("-Dhttp.port=<application-port>")`.
    However, this remapping should be unnecessary.
  - Exposing ports:
    There seems to be no need to expose ports via Docker.
    Without explicit exposure, the container does not listen to any *external* communication.
    The `docker-compose.yml` maps the *internal* port to the desired target port,
    and all external communication then proceeds via the target port.
    Such a construction has the benefit of the port being configurable at application start time,
    instead of relying on the correct setting while building the Docker image.
  - When starting the service via `docker-compose.yml` remove the `.env` file entries,
    because both the `deployment.env` and the `.env` files are read (in that order).
    This should be a workaround - a better solution is preferable!
- Working local (dev) mailer setup
  ```hocon
  play.mailer {
    host = "localhost"
    tls = no
    from = "foodie@luth"
    port = 25
    debug = yes
  }
  ```
- There are the following caveats when using a `localhost` mailer
  - The Docker networks need to be allowed explicitly.
    In the case of `postfix` add the corresponding networks to `mynetworks`.
  - The Docker networks may need to be controlled such that the range is sensible.
    It is possible to limit the range, cf. [here](https://serverfault.com/questions/916941/configuring-docker-to-not-use-the-172-17-0-0-range)
  - Neither a user nor a password is necessary, because the service is always running.
  - `localhost` needs to be exposed to Docker.
    To do that add
    ```yaml
    extra_hosts:
    - "host.docker.internal:host-gateway"
    ```
    to the desired service (usually `backend`).
    Then use `host.docker.internal` as a reference to `localhost`.
    N.B.: In a Docker container `localhost` is the container itself
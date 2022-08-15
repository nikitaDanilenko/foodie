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
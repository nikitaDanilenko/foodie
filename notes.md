* The path to the foodie db in Docker needs to be set correctly.
* `sudo /home/nda/.sdkman/candidates/sbt/current/bin/sbt "Docker / publishLocal"`
  creates a correct local image, which can be fetched with `foodie:latest`
* Docker configuration may need some adjustments in `build.sbt`
  - Either set everything so the publishing pushes to DockerHub
  - or configure correct build steps, build, and publish manually
* `deployment.env` should most likely not be committed
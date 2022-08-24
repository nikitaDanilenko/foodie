### Database
1. Create a database, a corresponding user, and connect the two:
   ```
   > psql -U postgres
   psql> create database <foodie>;
   psql> create user <foodie> with encrypted password <password>;
   psql> grant all privileges on database <foodie> to <foodie>;
   psql> grant pg_read_server_files to "<foodie>";
   ```
   The last command is important for the population of the actual CNF database.
2. Populate the CNF database by once running the script under `scripts/populate_cnf_db.sql`.
   To achieve that run the following steps:
   1. Open a console in the project folder 
   2. `> psql -U postgres`
   3. It may be necessary to switch to the project folder in `psql` as well.
      This can be achieved with `psql> \cd <absolute path>;`.
   4. `psql> \ir scripts/populate_cnf_db.sql`
   5. In case of Docker:
      1. The script files are copied to `/tmp/scripts` via `docker-compose.yml`.
      2. Connect to container `docker exec -it postgres /bin/bash`.
      3. Change into `tmp` via `cd /tmp`.
      4. Run `psql -U <foodie-user> -d <foodie-database> -h db`, enter the password.
      5. Run the script exactly as above.
   6. Why not a migration?
      There are several reasons for that:
      1. To `copy from` via SQL the user needs to be a superuser, which may be problematic.
      2. `copy from` does not handle relative paths, i.e. one needs an absolute path.
         Absolute paths present an unnecessary constraint and impede development, and deployment.
      3. In theory one may use a different population set or no population at all.
         Both work fine with an external population, but not with a migration.
3. The system scans for migrations in the folder `conf/db/migrations/default`
   and applies new ones.
   After a migration one should re-generate database related code:
    1. `sbt slickGenerate` generates the base queries, and types.
    
### Minimal Docker database backup strategy

Depending on the setup the commands below may need to be prefixed with `sudo`.

1. Start containers detached `docker compose up -d`
1. Connect to the container `docker compose run db bash`
1. Dump the database as insert statements (for better debugging):
   `pg_dump -h <container-name> -d <database-name> -U <user-name> --inserts -W > /tmp/<backup-file-name>.sql`.
   You will be prompted for the password for said user.
   Moving the file to `/tmp` handles possible access issues.
1. Find the id the desired container: `docker ps`
1. In a third CLI copy the backup file to your local file system:
   `docker cp <container-id>:/tmp/<backup-file-name>.sql <path-on-local-file-system>`

### Deployment

For the moment the deployment is handled manually.
There needs to be a running Docker service running on the target machine.

1. Connect to the target machine.
2. If this is the first deployment, clone Git project into a folder of your choosing.
3. Change into the local Git repository of the project.
4. Run `git pull`. It is possible that there will be a conflict with the `db.env`,
   if the development password has changed.
5. Make sure that `db.env` contains deployment values.
6. If this is the first deployment, create a file `deployment.env` containing
   all necessary environment variables (cf. `application.conf`).
7. Make sure that all necessary environment variables are set in `deployment.env`,
   and these variables contain the desired deployment values.
   As a reference, one can use the `.env` file - every key present in the `.env` file
   needs to be set in the `deployment.env` as well.
   Caveat: Avoid `#` symbols, because these can behave differently between
   `dotenv` and Docker.
8. Run `docker compose up` (possibly with `sudo`).
   If you want to deploy a specific version, update the image from `latest`
   to the desired tag in the `docker-compose.yml`.
9. If this is the first deployment,
   connect to a bash in the Docker `db` container,
   and perform the database setup steps described above.

### CI

[![Run tests](https://github.com/nikitaDanilenko/foodie/actions/workflows/tests.yml/badge.svg)](https://github.com/nikitaDanilenko/foodie/actions/workflows/tests.yml)
[![Build and publish](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml/badge.svg)](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml)
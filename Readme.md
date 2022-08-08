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

### CI

[![Run tests](https://github.com/nikitaDanilenko/foodie/actions/workflows/tests.yml/badge.svg)](https://github.com/nikitaDanilenko/foodie/actions/workflows/tests.yml)
[![Build and publish](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml/badge.svg)](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml)
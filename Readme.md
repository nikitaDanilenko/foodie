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

### CI

[![Scala CI](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml/badge.svg)](https://github.com/nikitaDanilenko/foodie/actions/workflows/scala.yml)
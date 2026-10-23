# holdipo db

Postgres migrations for the holdipo server.

Railway: add a Postgres database, then deploy this repo as a service with `DATABASE_URL` set to the Postgres reference.
`npm start` applies every file in `migrations/` once (tracked in `schema_migrations`) and then serves `/health`.

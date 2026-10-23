import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import postgres from "postgres";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const url = process.env.DATABASE_URL;
if (!url) {
  console.error("DATABASE_URL is required");
  process.exit(1);
}
const local = /localhost|127\.0\.0\.1|railway\.internal/.test(url);
const sql = postgres(url, { max: 1, ssl: local ? false : "require", onnotice: () => undefined });

const migrate = async () => {
  await sql`create table if not exists schema_migrations (id text primary key, applied_at timestamptz not null default now())`;
  const dir = path.join(root, "migrations");
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();
  for (const file of files) {
    const [done] = await sql`select 1 from schema_migrations where id = ${file}`;
    if (done) {
      console.log("already applied", file);
      continue;
    }
    await sql.begin(async (tx) => {
      await tx.unsafe(fs.readFileSync(path.join(dir, file), "utf8"));
      await tx`insert into schema_migrations (id) values (${file})`;
    });
    console.log("applied", file);
  }
  console.log("migrations complete");
};

migrate()
  .then(() => sql.end())
  .catch(async (err) => {
    console.error(err);
    await sql.end({ timeout: 1 });
    process.exit(1);
  });

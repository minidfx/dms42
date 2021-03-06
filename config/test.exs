use Mix.Config

config :dms42,
  documents_path: "documents",
  thumbnails_path: "thumbnails"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dms42, Dms42Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :dms42, Dms42.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dms42_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

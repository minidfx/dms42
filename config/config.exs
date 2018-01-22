# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :dms42,
  ecto_repos: [Dms42.Repo],
  documents_path: "documents"

# Configures the endpoint
config :dms42, Dms42Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7xDci3+lSgpch6uCZJNV7fjmeh0HUaDw7kpfbIzTVDPE5l/pespIJ2npKJtvem5+",
  render_errors: [view: Dms42Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Dms42.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

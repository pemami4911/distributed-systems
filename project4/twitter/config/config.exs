# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :twitter,
  ecto_repos: [Twitter.Repo]

# Configures the endpoint
config :twitter, TwitterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DNaYUiCWTnpXIdzy0p2asbKnS2bvst5Rnuq7fU6VOXyrKe+oPjAsJwA4JEd8W8C9",
  render_errors: [view: TwitterWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Twitter.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warn
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

config :guardian, Guardian,
 issuer: "Twitter.#{Mix.env}",
 ttl: {30, :days},
 verify_issuer: true,
 serializer: Twitter.GuardianSerializer,
 secret_key: to_string(Mix.env) <> "yyeeeaabooiii"
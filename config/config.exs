# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :poker_plan,
  ecto_repos: [PokerPlan.Repo]

# Configures the endpoint
config :poker_plan, PokerPlanWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PokerPlanWeb.ErrorHTML, json: PokerPlanWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PokerPlan.PubSub,
  live_view: [signing_salt: "K7jD+e0I"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :poker_plan, PokerPlan.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :poker_plan, :pow,
  web_mailer_module: PokerPlanWeb,
  web_module: PokerPlanWeb,
  user: PokerPlan.Data.User,
  repo: PokerPlan.Repo,
  # extensions: [PowResetPassword, PowEmailConfirmation],
  extensions: [],
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  mailer_backend: PokerPlanWeb.Pow.Mailer,
  routes_backend: PokerPlanWeb.Pow.Routes

config :poker_plan, PokerPlanWeb.Pow.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "SG.x.x"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

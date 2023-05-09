import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :poker_plan, PokerPlan.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "poker_plan_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :poker_plan, PokerPlanWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "z3rxAQORRE0jKziNVsJbaeKuEuR9Sv8HJymxtegQscegt0qHYDslNPM1yrLCAM9f",
  server: false

# In test we don't send emails.
config :poker_plan, PokerPlan.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
# config :logger, level: :warning
config :logger, level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Lower the iterations count in test environment to speed up tests
config :pow, Pow.Ecto.Schema.Password, iterations: 1

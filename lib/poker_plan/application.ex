defmodule PokerPlan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PokerPlanWeb.Telemetry,
      # Start the Ecto repository
      PokerPlan.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: PokerPlan.PubSub},
      # Start Finch
      {Finch, name: PokerPlan.Finch},
      # Start the Endpoint (http/https)
      PokerPlanWeb.Endpoint,
      # Start a worker by calling: PokerPlan.Worker.start_link(arg)
      # {PokerPlan.Worker, arg}
      # {Registry, keys: :unique, name: PokerPlan.Rounds.RoundRegistry},
      # {PokerPlan.Rounds.RoundsStore, name: PokerPlan.App.RoundsStore}
      {PokerPlan.Rounds.RoundsStore, name: PokerPlan.Rounds.RoundsStore}
      # {Registry, keys: :unique, name: PokerPlan.TaskRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PokerPlan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PokerPlanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

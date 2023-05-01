defmodule PokerPlanWeb.Router do
  use PokerPlanWeb, :router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowResetPassword, PowEmailConfirmation]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PokerPlanWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/" do
    pipe_through(:browser)

    pow_routes()
    pow_extension_routes()
  end

  scope "/", PokerPlanWeb do
    pipe_through(:browser)

    live("/rounds", RoundLive.Index, :index)
    live("/rounds/new", RoundLive.Index, :new)
    live("/rounds/:round_id/edit", RoundLive.Index, :edit)

    live("/rounds/:round_id", RoundLive.Show, :show)
    live("/rounds/:round_id/show/edit", RoundLive.Show, :edit)

    scope "/rounds/:round_id" do
      live("/tasks/new", RoundLive.Show, :new_task)
      live("/tasks/:id/edit", RoundLive.Show, :edit_task)
      live("/tasks/:id/estimations", RoundLive.Show, :estimations)
    end

    get("/", PageController, :home)
  end

  # Other scopes may use custom stacks.
  # scope "/api", PokerPlanWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:poker_plan, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: PokerPlanWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end

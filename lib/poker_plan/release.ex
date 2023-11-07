defmodule PokerPlan.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :poker_plan

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def reset_password(user_email, new_password \\ "12345678") do
    # Need to start the app (but don't need endpoint and other children running).
    load_app()
    Application.put_env(@app, :minimal, true)
    Application.ensure_all_started(@app)

    # Assuming we have just single repo.
    [repo] = repos()

    PokerPlan.Data.User
    |> repo.get_by(email: user_email)
    |> PokerPlan.Data.User.reset_password_changeset(%{
      password: new_password,
      password_confirmation: new_password
    })
    |> repo.update()

    IO.puts(
      "Password has been reset successfully (email: #{user_email}, new password: #{new_password})"
    )
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

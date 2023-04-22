defmodule PokerPlanWeb.SignInLive do
  use PokerPlanWeb, :live_view
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Sign in
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/registration/create"} class="font-semibold text-brand hover:underline">
            Register
          </.link>
          now.
        </:subtitle>
      </.header>

      <.simple_form :let={f} for={@changeset} as={:user} action={@action} phx-update="ignore">
        <.error :if={@changeset.action}>
          Oops, something went wrong! Please check the errors below.
        </.error>
        <.input
          field={f[Pow.Ecto.Schema.user_id_field(@changeset)]}
          type={(Pow.Ecto.Schema.user_id_field(@changeset) == :email && "email") || "text"}
          label={Phoenix.Naming.humanize(Pow.Ecto.Schema.user_id_field(@changeset))}
          required
        />
        <.input field={f[:password]} type="password" label="Password" value={nil} required />

        <:actions>
          :let={f}
          <.link
            href={
              Pow.Phoenix.Routes.path_for(
                @conn,
                PowResetPassword.Phoenix.ResetPasswordController,
                :new
              )
            }
            class="text-sm font-semibold"
          >
            Forgot your password?
          </.link>
        </:actions>

        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # socket.assigns.changeset = %PokerPlan.Users.User{}
    # IO.inspect(socket, label: "socket")
    # IO.inspect(socket.params, label: "socket.params")

    changeset = %PokerPlan.Users.User{} |> Ecto.Changeset.change()

    assigns =
      socket.assigns
      |> Map.put(:changeset, changeset)
      |> Map.put(:action, :new)

    {:ok, %{socket | assigns: assigns}}
    # {:ok, Map.put(socket, :changeset, )}
    # {:ok, Phoenix.Component.assign(socket, :}
  end
end

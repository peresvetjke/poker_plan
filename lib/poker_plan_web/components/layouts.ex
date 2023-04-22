defmodule PokerPlanWeb.Layouts do
  use PokerPlanWeb, :html

  embed_templates "layouts/*"

  def nav_links(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <b :if={@current_user}>
        <%= Pow.Plug.current_user(@conn).email %>
      </b>
      <.link :if={@current_user} href={~p"/session"} method="delete">
        Sign out
      </.link>
      <.link :if={is_nil(@current_user)} navigate={~p"/session/new"}>
        Sign In
      </.link>
      <.link :if={is_nil(@current_user)} navigate={~p"/registration/new"}>
        Registration
      </.link>
    </div>
    """
  end
end

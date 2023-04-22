defmodule PokerPlanWeb.CounterLive do
  use PokerPlanWeb, :live_view

  def render(assigns) do
    ~H"""
    Current counter: <%= @counter %>
    """
  end

  # def mount(_params, %{"current_user_id" => user_id}, socket) do
  def mount(_params, _session, socket) do
    # temperature = Thermostat.get_user_reading(user_id)
    new_socket =
      socket
      |> assign(:counter, 0)
      |> assign(:current_user, nil)

    {:ok, new_socket}
  end
end

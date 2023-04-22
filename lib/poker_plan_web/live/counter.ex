defmodule PokerPlanWeb.CounterLive do
  use PokerPlanWeb, :live_view

  def render(assigns) do
    ~H"""
    Current counter: <%= @counter %>
    """
  end

  # def mount(_params, %{"current_user_id" => user_id}, socket) do
  def mount(_params, _session, socket) do
    # IO.inspect
    # # temperature = Thermostat.get_user_reading(user_id)
    assigns =
      socket.assigns
      |> Map.put(:current_user, nil)
      |> Map.put(:counter, 0)

    {:ok, %{socket | assigns: assigns}}
  end
end

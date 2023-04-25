defmodule PokerPlanWeb.RoundChannel do
  use PokerPlanWeb, :channel

  # @impl true
  # def join("round:lobby", payload, socket) do
  # if authorized?(payload) do
  #   {:ok, socket}
  # else
  #   {:error, %{reason: "unauthorized"}}
  # end
  # end

  @impl true
  def join("rounds:" <> round_id, _params, socket) do
    # if authorized?(payload) do
    {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (round:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

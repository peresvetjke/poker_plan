defmodule PokerPlanWeb.RoundLive.Index do
  use PokerPlanWeb, :live_view

  alias PokerPlan.Rounds
  alias PokerPlan.Data.Round

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rounds, Rounds.list_rounds())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"round_id" => id}) do
    id = String.to_integer(id)

    socket
    |> assign(:page_title, "Edit Round")
    |> assign(:round, Rounds.get_round!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Round")
    |> assign(:round, %Round{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rounds")
    |> assign(:round, nil)
  end

  @impl true
  def handle_info({PokerPlanWeb.RoundLive.FormComponent, {:saved, round}}, socket) do
    {:noreply, stream_insert(socket, :rounds, round)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    round = Rounds.get_round!(id)
    {:ok, _} = Rounds.delete_round(round)

    {:noreply, stream_delete(socket, :rounds, round)}
  end
end

defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.Rounds

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:round, Rounds.get_round!(id))}
  end

  defp page_title(:show), do: "Show Round"
  defp page_title(:edit), do: "Edit Round"
end

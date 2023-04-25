defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}

  @impl true
  def mount(%{"round_id" => round_id}, _session, socket) do
    Phoenix.PubSub.subscribe(PokerPlan.PubSub, "round:#{round_id}")

    pid = PokerPlan.Rounds.RoundsStore.get(round_id)
    :ok = PokerPlan.Rounds.Round.add_user(pid, socket.assigns.current_user)
    round = PokerPlan.Rounds.Round.get(pid)

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        round: round,
        task: %Task{round_id: round_id}
      )
      |> stream(:tasks, Tasks.list_tasks(round_id))

    IO.inspect(socket.assigns)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:saved, task}, socket) do
    {:noreply, stream_insert(socket, :tasks, task, at: 0)}
  end

  defp page_title(:show), do: "Show Round"
  defp page_title(:edit), do: "Edit Round"
  defp page_title(:new_task), do: "New Task"
  defp page_title(:edit_task), do: "Edit Task"

  defp apply_action(socket, :new_task, _params) do
    socket
    |> assign(
      page_title: "New Task",
      task: %Task{}
    )
  end

  defp apply_action(socket, :save_task, params) do
    IO.inspect(params, label: "params")

    socket
    |> assign(:page_title, "New Task")
  end

  defp apply_action(socket, :show, params) do
    socket
  end
end

defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}

  @impl true
  def mount(%{"round_id" => round_id}, _session, socket) do
    Phoenix.PubSub.subscribe(PokerPlan.PubSub, "round:#{round_id}")

    pid = PokerPlan.Rounds.RoundsStore.get(String.to_integer(round_id))
    :ok = PokerPlan.Rounds.Round.add_user(pid, socket.assigns.current_user)
    round_info = PokerPlan.Rounds.Round.get(pid)

    current_task_info =
      case round_info.current_task do
        nil -> nil
        pid -> PokerPlan.TaskFSM.info(pid)
      end

    IO.inspect("reloading page...")
    IO.inspect(round_info.current_task, label: "round_info.current_task")
    IO.inspect(round_info.current_task != nil, label: "@round_info.current_task != nil")

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        round_info: round_info,
        task: %Task{round_id: round_id},
        current_task: current_task_info
      )
      |> stream(:tasks, Tasks.list_tasks(round_id))
      |> stream(:users, round_info.users)

    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_id}",
      {:user_joined, socket.assigns.current_user}
    )

    IO.inspect(socket.assigns.round_info.current_task,
      label: "socket.assigns.round_info.current_task"
    )

    # IO.inspect(socket.assigns.round_info, label: "socket.assigns.round_info")
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

  @impl true
  def handle_info({:user_joined, user}, socket) do
    {:noreply, stream_insert(socket, :users, user, at: 0)}
  end

  defp page_title(:show), do: "Show Round"
  defp page_title(:edit), do: "Edit Round"
  defp page_title(:new_task), do: "New Task"
  defp page_title(:edit_task), do: "Edit Task"
  defp page_title(:start_task), do: "Start Task"

  defp apply_action(socket, :new_task, _params) do
    socket
    # |> assign(
    #   page_title: "New Task",
    #   task: %Task{}
    # )
  end

  defp apply_action(socket, :save_task, params) do
    IO.inspect(params, label: "params")

    socket
    |> assign(:page_title, "New Task")
  end

  defp apply_action(socket, :start_task, %{"round_id" => round_id, "id" => id}) do
    IO.inspect(id, label: "id")

    task =
      Enum.find(
        socket.assigns.round_info.round.tasks,
        fn x -> x.id == String.to_integer(id) end
      )

    # IO.inspect(task, label: "task")

    # IO.inspect(socket.assigns.round_info.current_task,
    #   label: "socket.assigns.round_info.current_task"
    # )

    # find()
    # IO.inspect(params, label: "params")
    task_pid =
      case PokerPlan.TaskFSM.start_link(task) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    round_pid = PokerPlan.Rounds.RoundsStore.get(String.to_integer(round_id))
    :ok = PokerPlan.Rounds.Round.set_current_task(round_pid, task_pid)
    # current_task = PokerPlan.TaskFSM.info(task_pid)
    round_info = PokerPlan.Rounds.Round.get(round_pid)
    IO.inspect(round_info.current_task, label: "round_info.current_task")
    IO.inspect(round_info.current_task != nil, label: "@round_info.current_task != nil")

    assign(socket, :round_info, round_info)
  end

  defp apply_action(socket, :show, params) do
    socket
  end
end

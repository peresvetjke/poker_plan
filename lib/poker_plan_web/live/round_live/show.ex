defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  import PokerPlan.CacheHelpers

  @impl true
  def mount(%{"round_id" => round_id}, session, socket) do
    Phoenix.PubSub.subscribe(PokerPlan.PubSub, "round:#{round_id}")

    round_id = String.to_integer(round_id)
    round = get_round(round_id)
    add_user_to_round(round.round, socket.assigns.current_user)

    {:ok, socket |> refresh_round_details(round)}
  end

  @impl true
  def handle_info(
        {:round_refreshed,
         %{round: %{id: round_id}, tasks_ids: tasks_ids, users_ids: users_ids} = round},
        socket
      ) do
    {:noreply, socket |> refresh_round_details(round)}
  end

  @impl true
  def handle_info(
        {:task_estimation_report, round_id, task_id},
        socket
      ) do
    {:noreply, push_patch(socket, to: ~p"/rounds/#{round_id}/tasks/#{task_id}/estimations")}
  end

  @impl true
  def handle_event("remove_user_from_round", %{"id" => id}, socket) do
    pid(:round, socket.assigns.round.round.id)
    |> PokerPlan.Round.remove_user(String.to_integer(id))

    {:noreply,
     socket
     |> put_flash(:info, "User removed successfully")}
  end

  @impl true
  def handle_event("estimate_task", %{"points" => points}, socket) do
    points = String.to_integer(points)
    estimate_task(socket.assigns.current_user, socket.assigns.current_task.task, points)

    {:noreply, socket}
  end

  def hide_modal do
    JS.hide("#current-task-modal")
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp page_title(:show), do: "Show Round"
  defp page_title(:edit), do: "Edit Round"
  defp page_title(:new_task), do: "New Task"
  defp page_title(:edit_task), do: "Edit Task"
  defp page_title(:start_task), do: "Start Task"
  defp page_title(:estimations), do: "Result"

  defp apply_action(socket, :new_task, _params) do
    socket
    |> assign(:page_title, page_title(:new_task))
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, page_title(:edit))
  end

  defp apply_action(socket, :estimations, %{"id" => task_id} = _params) do
    task_id = String.to_integer(task_id)
    task = load_record_using_cache(:task, task_id)
    estimations = task.estimations
    users_ids = estimations |> Enum.map(& &1.user_id)
    users = load_records_using_cache(:user, users_ids)

    socket
    |> assign(
      page_title: "Result",
      estimations: task.estimations,
      task_users: users
    )
  end

  defp apply_action(socket, :show, params) do
    socket
  end

  defp current_task(%{current_task_id: nil} = _round, _tasks), do: nil

  defp current_task(%{current_task_id: current_task_id} = _round, tasks) when is_list(tasks) do
    Enum.find(tasks, fn t -> t.task.id == current_task_id end)
  end

  defp get_round(id) when is_integer(id) do
    load_record_using_cache(:round, id)
  end

  defp add_user_to_round(
         %PokerPlan.Data.Round{id: round_id},
         %PokerPlan.Data.User{} = user
       ) do
    pid(:round, round_id)
    |> PokerPlan.Round.add_user(user)
  end

  defp estimate_task(
         %PokerPlan.Data.User{} = user,
         %PokerPlan.Data.Task{id: id} = _task,
         value
       )
       when is_integer(value) do
    pid(:task, id)
    |> PokerPlan.Task.estimate(user, value)
  end

  defp refresh_round_details(socket, %{tasks_ids: tasks_ids, users_ids: users_ids} = round) do
    tasks = load_records_using_cache(:task, tasks_ids)

    socket =
      socket
      |> assign(
        round: round,
        tasks: tasks,
        users: load_records_using_cache(:user, users_ids),
        current_task: current_task(round, tasks)
      )
  end
end

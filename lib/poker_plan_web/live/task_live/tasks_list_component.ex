defmodule PokerPlanWeb.TaskLive.TasksListComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.table id="tasks-list" rows={sorted_tasks(assigns.tasks)}>
        <:col :let={task} label="Title">
          <.live_component id={task.id} module={PokerPlanWeb.TaskLive.TaskComponent} task={task}>
          </.live_component>
        </:col>
        <:col :let={task} label="State"><%= task.state %></:col>
        <:col :let={task}>
          <%= if task.state == "finished" do %>
            <.link
              patch={~p"/rounds/#{task.round_id}/tasks/#{task}/estimations"}
              phx-click={JS.push_focus()}
            >
              <%= PokerPlanWeb.Icon.report(assigns) %>
            </.link>
          <% else %>
            <a
              class="align-baseline"
              href="#"
              phx-target={@myself}
              phx-click="switch_state"
              phx-value-id={task.id}
              phx-value-state={task.state}
            >
              <%= PokerPlanWeb.Icon.play_pause(assigns) %>
            </a>
          <% end %>
        </:col>
        <:col :let={task}>
          <a
            href="#"
            data-confirm="Are you sure?"
            phx-target={@myself}
            phx-click="delete_task"
            phx-value-id={task.id}
            phx-value-state={task.state}
          >
            <%= PokerPlanWeb.Icon.delete(assigns) %>
          </a>
        </:col>
      </.table>
    </div>
    """
  end

  def handle_event(
        "switch_state",
        %{"id" => id, "state" => "idle"},
        socket
      ) do
    PokerPlan.CacheHelpers.pid(:task, String.to_integer(id))
    |> PokerPlan.Task.start()

    {:noreply, socket}
  end

  def handle_event(
        "switch_state",
        %{"id" => id, "state" => "doing"},
        socket
      ) do
    PokerPlan.CacheHelpers.pid(:task, String.to_integer(id))
    |> PokerPlan.Task.stop()

    {:noreply, socket}
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    case delete_task(String.to_integer(id)) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task deleted successfully")}
    end
  end

  defp sorted_tasks(tasks) do
    order = ["doing", "idle", "hold", "finished"]

    # REFACTOR (use stream)
    tasks
    |> Enum.map(fn x -> x.task end)
    |> Enum.sort_by(fn task ->
      Enum.find_index(order, &(&1 == task.state))
    end)
  end

  defp delete_task(id) when is_integer(id) do
    case PokerPlan.Repo.get(PokerPlan.Data.Task, id) |> PokerPlan.Repo.delete() do
      {:ok, task} ->
        PokerPlan.CacheHelpers.pid(:round, task.round_id)
        |> PokerPlan.Round.remove_task(task)

        {:ok, task}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end

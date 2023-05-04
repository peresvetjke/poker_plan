defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}
  alias PokerPlan.App

  def button_style(assigns, value) do
    if assigns.current_user.is_spectator do
      "button-style cursor-not-allowed"
    else
      case App.current_task_user_estimation_value(
             assigns.round_info.round.id,
             assigns.current_user.id
           ) do
        ^value -> "button-style-set"
        _ -> "button-style"
      end
    end
  end

  def current_task(assigns) do
    ~H"""
    <br />

    <div class="rounded-lg border border-gray-400 p-4">
      <div class="mb-3">
        <span>Current task: </span><b><a href={assigns.current_task.title}> <%= PokerPlan.App.task_short_title(assigns.current_task.title) %></a></b>
      </div>

      <%= for i <- [1, 2, 3, 5, 8] do %>
        <button phx-click="estimate_task" phx-value-points={i} class={button_style(assigns, i)}>
          <%= i %>
        </button>
      <% end %>
    </div>
    """
  end

  def users_list(assigns) do
    sorted_users = assigns.round_info.users |> Enum.sort_by(fn u -> u.is_spectator end)

    ~H"""
    <.table id="users" rows={sorted_users}>
      <:col :let={user} label="User"><%= App.username(user) %></:col>

      <:col :let={user}>
        <%= if user.is_spectator do %>
          <%= PokerPlanWeb.Icon.eye(assigns) %>
        <% else %>
          <%= if @round_info.current_task_id do %>
            <%= if Map.get(@current_task_users_status, user.id) do %>
              <%= PokerPlanWeb.Icon.check_circle(assigns) %>
            <% end %>
          <% end %>
        <% end %>
      </:col>

      <:col :let={user}>
        <a
          href="#"
          data-confirm="Are you sure?"
          phx-click="remove_user_from_round"
          phx-value-id={user.id}
        >
          <%= PokerPlanWeb.Icon.delete(assigns) %>
        </a>
      </:col>
    </.table>
    """
  end

  def tasks_list(assigns) do
    order = ["doing", "idle", "hold", "finished"]

    tasks =
      Enum.sort_by(assigns.tasks, fn task ->
        Enum.find_index(order, &(&1 == task.state))
      end)

    ~H"""
    <.table id="tasks" rows={tasks}>
      <:col :let={task} label="Title">
        <a href={task.title}><%= PokerPlan.App.task_short_title(task.title) %></a>
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
          <a class="align-baseline" href="#" phx-click="start_task" phx-value-id={task.id}>
            <%= PokerPlanWeb.Icon.play_pause(assigns) %>
          </a>
        <% end %>
      </:col>
      <:col :let={task}>
        <a href="#" data-confirm="Are you sure?" phx-click="delete_task" phx-value-id={task.id}>
          <%= PokerPlanWeb.Icon.delete(assigns) %>
        </a>
      </:col>
    </.table>
    """
  end

  def estimations_report(assigns) do
    sorted_users =
      Enum.sort_by(
        assigns.task_users,
        fn user -> -Map.get(assigns.task_estimates, user.id) end
      )

    ~H"""
    <.table id="estimations_report" rows={sorted_users}>
      <:col :let={user} label="User">
        <%= App.username(user) %>
      </:col>
      <:col :let={user} label="Estimation">
        <%= Map.get(@task_estimates, user.id) %>
      </:col>
    </.table>
    """
  end

  @impl true
  def mount(%{"round_id" => round_id}, session, socket) do
    Phoenix.PubSub.subscribe(PokerPlan.PubSub, "round:#{round_id}")

    round_id = String.to_integer(round_id)
    round_info = App.round_info(round_id)
    App.add_user_to_round(round_info.round, socket.assigns.current_user)

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        round_info: round_info,
        task: %Task{round_id: round_id},
        current_user_id: socket.assigns.current_user.id,
        current_task: App.current_task(round_id),
        current_task_users_status: App.current_task_users_status(round_id),
        current_task_estimates: nil,
        tasks: round_info.round.tasks,
        users: round_info.users
      )

    {:ok, socket}
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
  end

  defp apply_action(socket, :edit, params) do
    socket
    |> assign(:page_title, page_title(:edit))
  end

  defp apply_action(socket, :save_task, params) do
    socket
    |> assign(:page_title, "New Task")
  end

  defp apply_action(socket, :estimations, %{"id" => task_id} = params) do
    task_id = String.to_integer(task_id)

    socket
    |> assign(
      page_title: "Result",
      task_estimates: App.task_estimates(task_id),
      task_users: App.task_users(task_id)
    )
  end

  def handle_info(
        {:round_refreshed, %{round: %{id: round_id, tasks: tasks}} = round_info},
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       round_info: round_info,
       current_task: App.current_task(round_id),
       current_task_users_status: App.current_task_users_status(round_id),
       tasks: tasks,
       users: round_info.users
     )}
  end

  def handle_info({:task_estimation_report, task}, socket) do
    {:noreply, push_patch(socket, to: ~p"/rounds/#{task.round_id}/tasks/#{task}/estimations")}
  end

  def handle_event("start_task", %{"id" => task_id}, socket) do
    task_id = String.to_integer(task_id)

    task =
      socket.assigns.round_info.round.tasks
      |> Enum.find(fn t -> t.id == task_id end)

    App.start_task(task)

    {:noreply, socket}
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    case App.delete_task(String.to_integer(id)) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task deleted successfully")}
    end
  end

  def handle_event("remove_user_from_round", %{"id" => id}, socket) do
    case App.remove_user_from_round(
           String.to_integer(id),
           socket.assigns.round_info.round.round_id
         ) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "User removed successfully")}
    end
  end

  def handle_event("estimate_task", %{"points" => points}, socket) do
    points = String.to_integer(points)
    App.estimate_task(socket.assigns.current_user, socket.assigns.current_task, points)
    {:noreply, socket}
  end

  defp apply_action(socket, :show, params) do
    socket
  end

  def hide_modal do
    JS.hide("#current-task-modal")
  end
end

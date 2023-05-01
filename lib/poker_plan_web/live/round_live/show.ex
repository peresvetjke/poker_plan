defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}
  alias PokerPlan.App

  def button_style(assigns, value) do
    # IO.inspect(assigns, "assigns in button_style")

    IO.inspect(value, label: "value")
    IO.inspect(assigns.current_task_users_status, label: "assigns.current_task_users_status")

    IO.inspect(Map.get(assigns.current_task_users_status, assigns.current_user_id),
      label: "Map.get(assigns.current_task_users_status, assigns.current_user_id)"
    )

    case App.current_task_user_estimation_value(
           assigns.round_info.round.id,
           assigns.current_user_id
         ) do
      ^value -> "button-style-set"
      _ -> "button-style"
    end

    # case Map.get(assigns.current_task_users_status, assigns.current_user.id) do
    #   nil -> "button-style"
    #   _value -> "button-style:hover"
    # end
  end

  def current_task(assigns) do
    ~H"""
    <br />

    <div class="rounded-lg border border-gray-400 p-4">
      <div class="mb-3">
        <span>Current task: </span><b><%= assigns.current_task.title %></b>
      </div>

      <%= for i <- [1, 2, 3, 5, 8] do %>
        <button phx-click="estimate_task" phx-value-points={i} class={button_style(assigns, i)}>
          <%= i %>
        </button>
      <% end %>
      <%!-- <div class="btn-group"> --%>
      <%!-- <%= estimation_button(assigns, 1) %> --%>
      <%!-- <%= @socket.current_user.id %> --%>
      <%!-- </.estimation_button> --%>
      <%!-- <.estimation_button current_task_users_status={@current_task_users_status} value={2}>
        </.estimation_button>
        <.estimation_button current_task_users_status={@current_task_users_status} value={3}>
        </.estimation_button>
        <.estimation_button current_task_users_status={@current_task_users_status} value={5}>
        </.estimation_button>
        <.estimation_button current_task_users_status={@current_task_users_status} value={8}>
        </.estimation_button> --%>
      <%!-- </div> --%>
    </div>
    """
  end

  def estimation_button(assigns, value) do
    style =
      case Map.get(assigns.current_task_users_status, assigns.current_user_id) do
        nil -> "button-style"
        _value -> "button-style:hover"
      end

    # class="bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
    ~H"""
    <button phx-click="estimate_task" phx-value-points={value} class={style}>
      value <%!-- <%= @value %> --%>
    </button>
    """
  end

  # def handle_event("hover", %{hover: true}, socket) do
  #   {:noreply, assign(socket, hovering: true)}
  # end

  # def handle_event("hover", %{hover: false}, socket) do
  #   {:noreply, assign(socket, hovering: false)}
  # end

  def users_list(assigns) do
    # current_task_users_status
    ~H"""
    <.table id="users" rows={@round_info.users}>
      <:col :let={user} label="User"><%= user.username %></:col>

      <:col :let={user} :if={@round_info.current_task_id}>
        <%= if Map.get(@current_task_users_status, user.id) do %>
          <%= PokerPlanWeb.Icon.check_circle(assigns) %>
        <% end %>
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
      <:col :let={task} label="Title"><%= task.title %></:col>
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

  def task_actions(assigns) do
    ~H"""

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
        <%= user.username %>
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
      # |> Phoenix.Component.assign_new(:current_user, fn ->
      #   PokerPlanWeb.UserLiveAuth.get_user(socket, session)
      # end)
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

    # |> stream(:tasks, round_info.round.tasks)
    # |> stream(:users, round_info.users)

    IO.inspect(socket, label: "mount...socket")
    IO.inspect(socket.assigns.current_user_id, label: "mount...socket.assigns.current_user_id")
    IO.inspect(session, label: "mount...session")

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
    # |> assign(
    #   page_title: "New Task",
    #   task: %Task{}
    # )
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
    # task_id
    task_id = String.to_integer(task_id)
    # from e in PokerPlan.Data.Estimation, where: task_id == e.id

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
       #  current_task_estimates: nil,
       #  current_task_estimates: App.current_task_estimates(round_id),
       #  round_info.round.tasks
       #  |> Enum.find(fn x -> x.id == round_info.current_task_id end),
       tasks: tasks,
       users: round_info.users
     )}
  end

  def handle_info({:task_estimation_report, task}, socket) do
    # IO.inspect(socket: "socket")
    # {:noreply, socket |> assign(task_estimates: App.task_estimates)}
    {:noreply, push_patch(socket, to: ~p"/rounds/#{task.round_id}/tasks/#{task}/estimations")}
  end

  # def handle_info({:current_task_updated, current_task_id, current_task_estimates}, socket) do
  #   {:noreply,
  #    socket
  #    |> assign(current_task_id: current_task_id, current_task_estimates: current_task_estimates)}
  # end

  # defp apply_action(socket, :start_task, %{"round_id" => round_id, "id" => id}) do
  def handle_event("start_task", %{"id" => task_id}, socket) do
    # round_id = String.to_integer(round_id)
    task_id = String.to_integer(task_id)

    task =
      socket.assigns.round_info.round.tasks
      |> Enum.find(fn t -> t.id == task_id end)

    App.start_task(task)

    {:noreply, socket}
    # assign(socket, :round_info, round_info)
  end

  # def handle_event("result", %{"id" => task_id}, socket) do
  #   task_id = String.to_integer(task_id)

  #   # task =
  #   #   socket.assigns.round_info.round.tasks
  #   #   |> Enum.find(fn t -> t.id == task_id end)

  #   {:noreply, assign(socket, current_task_estimates: App.task_estimates(task_id))}
  #   # assign(socket, :round_info, round_info)
  # end

  def handle_event("delete_task", %{"id" => id}, socket) do
    # task = Tasks.get_task!(String.to_integer(id))

    case App.delete_task(String.to_integer(id)) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task deleted successfully")}

        # |> notify_parent()

        #  |> push_patch(to: socket.assigns.patch)}

        # {:error, %Ecto.Changeset{} = changeset} ->
        #   {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("estimate_task", %{"points" => points}, socket) do
    points = String.to_integer(points)
    # pid = socket.assigns.current_task
    # # PokerPlan.Rounds.Rpi.vote(pid, socket.assigns.current_user.id, points)
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

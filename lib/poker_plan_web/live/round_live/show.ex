defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}
  alias PokerPlan.App

  def current_task(assigns) do
    ~H"""
    <br />

    <div class="bg-gray-100 rounded-lg border border-gray-400 p-4">
      <div class="mb-3"><span>Current task: </span><b><%= @current_task.title %></b></div>
      <div class="btn-group">
        <.estimation_button value={1}></.estimation_button>
        <.estimation_button value={2}></.estimation_button>
        <.estimation_button value={3}></.estimation_button>
        <.estimation_button value={5}></.estimation_button>
        <.estimation_button value={8}></.estimation_button>
      </div>
    </div>
    """
  end

  def estimation_button(assigns) do
    # class="bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
    ~H"""
    <button
      phx-click="estimate_task"
      phx-value-points={@value}
      class="bg-gray-500 hover:bg-gray-400 text-white font-bold py-2 px-4 border-b-4 border-gray-700 hover:border-gray-500 rounded"
    >
      <%= @value %>
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
    ~H"""
    <.table id="users" rows={@round_info.users}>
      <:col :let={user} label="User"><%= user.username %></:col>
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
      <:col :let={task} label="Status"><%= task.state %></:col>
      <:action :let={task}>
        <.link phx-click="delete_task" phx-value-id={task.id}>Delete</.link>
      </:action>
      <:action :let={task}>
        <%= if task.state == "finished" do %>
          <.link phx-click="result" phx-value-id={task.id}>Result</.link>
        <% else %>
          <.link phx-click="start_task" phx-value-id={task.id}>Start</.link>
        <% end %>
      </:action>
    </.table>
    """
  end

  def estimations_report(assigns) do
    ~H"""
    <.table id="estimations_report" rows={@users}>
      <:col :let={user} label="User">
        <%= user.username %>
      </:col>
      <:col :let={user} label="Estimation">
        <%= Map.get(@current_task_estimates, user.id) %>
      </:col>
    </.table>
    """
  end

  @impl true
  def mount(%{"round_id" => round_id}, _session, socket) do
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
        current_task: App.current_task(round_id),
        current_task_users_status: App.current_task_users_status(round_id),
        current_task_estimates: nil,
        tasks: round_info.round.tasks,
        users: round_info.users
      )

    # |> stream(:tasks, round_info.round.tasks)
    # |> stream(:users, round_info.users)

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

  def handle_info({:task_estimation_report, estimates}, socket) do
    {:noreply, socket |> assign(current_task_estimates: estimates)}
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

  def handle_event("result", %{"id" => task_id}, socket) do
    task_id = String.to_integer(task_id)

    # task =
    #   socket.assigns.round_info.round.tasks
    #   |> Enum.find(fn t -> t.id == task_id end)

    {:noreply, assign(socket, current_task_estimates: App.task_estimates(task_id))}
    # assign(socket, :round_info, round_info)
  end

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
end

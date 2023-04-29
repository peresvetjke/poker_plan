defmodule PokerPlanWeb.RoundLive.Show do
  use PokerPlanWeb, :live_view

  alias PokerPlan.{Rounds, Tasks}

  def current_task(assigns) do
    ~H"""
    <div class="bg-gray-100 p-4">
      <p><%= @current_task_info.task.title %></p>
      <div class="btn-group">
        <.button phx-click="estimate_task" phx-value-points={1}>1</.button>
        <.button phx-click="estimate_task" phx-value-points={2}>2</.button>
        <.button phx-click="estimate_task" phx-value-points={3}>3</.button>
      </div>
    </div>
    """
  end

  def users_list(assigns) do
    ~H"""
    <.table id="users" rows={@round_info.users}>
      <:col :let={user} label="User"><%= user.username %></:col>
    </.table>
    """
  end

  def tasks_list(assigns) do
    ~H"""
    <.table id="tasks" rows={@streams.tasks}>
      <:col :let={{_id, task}} label="Title"><%= task.title %></:col>
      <:col :let={{_id, task}} label="Status"><%= task.state %></:col>
      <:action :let={{_id, task}}>
        <.link phx-click="delete_task" phx-value-id={task.id}>Delete</.link>
      </:action>
      <:action :let={{_id, task}}>
        <.link phx-click="start_task" phx-value-id={task.id}>Start</.link>
      </:action>
    </.table>
    """
  end

  def user_estimation(user, current_task_info) do
    case current_task_info do
      nil ->
        ""

      current_task_info ->
        value = current_task_info.estimates |> Map.get(user.id)

        case value do
          true -> "+"
          false -> "-"
          nil -> "nil"
        end
    end
  end

  @impl true
  def mount(%{"round_id" => round_id}, _session, socket) do
    Phoenix.PubSub.subscribe(PokerPlan.PubSub, "round:#{round_id}")

    round_id = String.to_integer(round_id)
    round_info = PokerPlan.Rounds.get_round!(round_id)
    PokerPlan.Rounds.add_user(round_info.round, socket.assigns.current_user)

    current_task_info =
      case round_info.current_task do
        nil -> nil
        pid -> PokerPlan.Rounds.Task.get(pid)
      end

    socket =
      socket
      |> assign(
        page_title: page_title(socket.assigns.live_action),
        round_info: round_info,
        task: %Task{round_id: round_id},
        current_task_info: current_task_info
      )
      |> stream(:tasks, round_info.round.tasks)
      |> stream(:users, round_info.users)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:user_joined, user}, socket) do
    {:noreply, stream_insert(socket, :users, user, at: 0)}
  end

  @impl true
  def handle_info({:task_created, task}, socket) do
    {:noreply, socket |> stream_insert(:tasks, task, at: 0)}
  end

  @impl true
  def handle_info({:round_refreshed, round_info}, socket) do
    {:noreply, assign(socket, :round_info, round_info)}
  end

  @impl true
  def handle_info({:task_updated, task}, socket) do
    previous = Enum.find(socket.assigns.round_info.round.tasks, fn t -> t.id == task.id end)

    {
      :noreply,
      socket
      #  |> stream_insert(:tasks, task)}
      # }
      # |> stream_insert(:tasks, task)
      # }

      # |> stream_delete(:tasks, previous)
      |> stream_insert(:tasks, task, at: -1)
    }
  end

  @impl true
  def handle_info(:current_task_deleted, socket) do
    {:noreply, assign(socket, :current_task_info, nil)}
  end

  @impl true
  def handle_info({:task_deleted, task}, socket) do
    # current_task_id =
    #   case(socket.assigns.current_task_info) do
    #     nil ->
    #       nil

    #     task_info ->
    #       task_info.task.id
    #   end

    # task_id = task.id

    # socket =
    #   case current_task_id do
    #     ^task_id -> assign(socket, :current_task_info, nil)
    #     _ -> socket
    #   end

    {:noreply,
     socket
     #  |> stream_insert(:tasks, task)}

     |> stream_delete(:tasks, task)}

    #  |> stream_insert(:tasks, task, at: -1)}
  end

  @impl true
  def handle_info({:task_started, current_task_info}, socket) do
    {:noreply, assign(socket, :current_task_info, current_task_info)}
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

  # defp apply_action(socket, :start_task, %{"round_id" => round_id, "id" => id}) do
  def handle_event("start_task", %{"id" => task_id}, socket) do
    # round_id = String.to_integer(round_id)
    task_id = String.to_integer(task_id)

    task =
      socket.assigns.round_info.round.tasks
      |> Enum.find(fn t -> t.id == task_id end)

    PokerPlan.Rounds.start_task(task)

    {:noreply, socket}
    # assign(socket, :round_info, round_info)
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    task = Tasks.get_task!(String.to_integer(id))

    case Tasks.delete_task(task) do
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
    pid = socket.assigns.round_info.current_task
    PokerPlan.Rounds.Task.vote(pid, socket.assigns.current_user.id, points)
    {:noreply, socket}
  end

  defp apply_action(socket, :show, params) do
    socket
  end
end

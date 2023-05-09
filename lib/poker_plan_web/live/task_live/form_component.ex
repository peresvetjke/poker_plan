defmodule PokerPlanWeb.TaskLive.FormComponent do
  use PokerPlanWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="task-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save_task"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <%= Phoenix.HTML.Form.hidden_input(@form, :round_id, value: @round.round.id) %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Task</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task} = assigns, socket) do
    changeset = change_task(task)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save_task", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.action, task_params)
  end

  defp save_task(socket, :new_task, %{"round_id" => round_id} = task_params) do
    task_params = %{task_params | "round_id" => String.to_integer(round_id)}

    case create_task(task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp change_task(%PokerPlan.Data.Task{} = task, attrs \\ %{}) do
    PokerPlan.Data.Task.changeset(task, attrs)
  end

  defp create_task(%{"round_id" => round_id} = attrs) when is_integer(round_id) do
    case %PokerPlan.Data.Task{}
         |> PokerPlan.Data.Task.changeset(attrs)
         |> PokerPlan.Repo.insert() do
      {:ok, task} ->
        PokerPlan.CacheHelpers.pid(:round, round_id)
        |> PokerPlan.Round.add_task(task)

        {:ok, task}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end

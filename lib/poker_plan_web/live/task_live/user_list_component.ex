defmodule PokerPlanWeb.TaskLive.UserListComponent do
  use PokerPlanWeb, :live_component

  alias PokerPlan.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Something</p>
    </div>
    """
  end

  #   <%= if @current_task_info != nil do %>
  #   <div>
  #     <.button phx-click="estimate_task" phx-value-vote={1}>1</.button>
  #   </div>
  # <% end %>
  # <table>
  #   <tbody id="users" phx-target="users-list">
  #     <tr :for={{dom_id, user} <- @streams.users} id={dom_id}>
  #       <td><%= user.username %></td>
  #       <td><%= user_estimation(user, @current_task_info) %></td>
  #     </tr>
  #   </tbody>
  # </table>

  # @impl true
  # def update(%{task: task} = assigns, socket) do
  #   changeset = Tasks.change_task(task)

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_form(changeset)}
  # end

  # @impl true
  # def handle_event("validate", %{"task" => task_params}, socket) do
  #   changeset =
  #     socket.assigns.task
  #     |> Tasks.change_task(task_params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign_form(socket, changeset)}
  # end

  # def handle_event("save_task", %{"task" => task_params}, socket) do
  #   save_task(socket, socket.assigns.action, task_params)
  # end

  # defp save_task(socket, :edit, task_params) do
  #   case Tasks.update_task(socket.assigns.task, task_params) do
  #     {:ok, task} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Task updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

  # defp save_task(socket, :new_task, task_params) do
  #   case Tasks.create_task(task_params) do
  #     {:ok, task} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Task created successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

  # defp assign_form(socket, %Ecto.Changeset{} = changeset) do
  #   assign(socket, :form, to_form(changeset))
  # end

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

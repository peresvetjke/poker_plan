defmodule PokerPlanWeb.TaskLive.UsersListComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.table id="users" rows={sorted_users(@users)}>
        <:col :let={user} label="User"><%= username(user) %></:col>

        <:col :let={user}>
          <%= if user.is_spectator do %>
            <%= PokerPlanWeb.Icon.eye(assigns) %>
          <% else %>
            <%= if @current_task do %>
              <%= if player_voted(assigns, user) do %>
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
    </div>
    """
  end

  defp player_voted(assigns, user) do
    assigns.current_task.voted_users_ids
    |> Enum.any?(fn id -> id == user.id end)
  end

  defp sorted_users(users) do
    users |> Enum.sort_by(fn u -> u.is_spectator end)
  end

  defp username(%PokerPlan.Data.User{username: username, email: email} = user) do
    case username do
      nil ->
        [name | _] = email |> String.split("@")
        name

      name ->
        name
    end
  end
end

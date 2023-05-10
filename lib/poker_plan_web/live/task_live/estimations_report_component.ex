defmodule PokerPlanWeb.TaskLive.EstimationsReportComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.table id="estimations_report" rows={rows(assigns)}>
        <:col :let={row} label="User">
          <%= if is_total(row) do %>
            <u><%= row_label(assigns, row) %></u>
          <% else %>
            <%= row_label(assigns, row) %>
          <% end %>
        </:col>
        <:col :let={row} label="Estimation">
          <%= row_value(assigns, row) %>
        </:col>
      </.table>
    </div>
    """
  end

  defp rows(assigns), do: sorted_estimations(assigns) ++ totals(assigns)

  defp sorted_estimations(assigns), do: Enum.sort_by(assigns.estimations, &(-&1.value))

  defp totals(assigns), do: [total_average(assigns)]

  defp total_average(assigns) do
    %{
      row_label: "Average",
      row_value:
        Enum.reduce(assigns.estimations, 0, fn e, acc -> acc + e.value end) /
          length(assigns.estimations)
    }
  end

  defp row_label(assigns, %PokerPlan.Data.Estimation{user_id: user_id} = _row) do
    user(assigns.task_users, user_id) |> username()
  end

  defp row_label(_assigns, %{row_label: row_label}), do: row_label

  defp row_value(_assigns, %PokerPlan.Data.Estimation{value: value} = _row), do: value
  defp row_value(_assigns, %{row_value: row_value}), do: row_value

  defp user(users, id), do: Enum.find(users, fn u -> u.id == id end)

  defp username(%PokerPlan.Data.User{username: username, email: email}) do
    case username do
      nil ->
        [name | _] = email |> String.split("@")
        name

      name ->
        name
    end
  end

  defp is_total(%{row_label: _row_label}), do: true
  defp is_total(_row), do: false
end

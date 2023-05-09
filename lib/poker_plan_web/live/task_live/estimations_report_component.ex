defmodule PokerPlanWeb.TaskLive.EstimationsReportComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.table id="estimations_report" rows={sorted_estimations(@estimations)}>
        <:col :let={estimation} label="User">
          <%= user(@task_users, estimation.user_id) |> username() %>
        </:col>
        <:col :let={estimation} label="Estimation">
          <%= estimation.value %>
        </:col>
      </.table>
    </div>
    """
  end

  defp sorted_estimations(estimations), do: Enum.sort_by(estimations, &(-&1.value))
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
end

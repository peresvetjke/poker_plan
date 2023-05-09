defmodule PokerPlanWeb.TaskLive.TaskComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    title = assigns.task.title

    if String.contains?(title, "/") do
      ~H"""
      <span><a target="_blank" href={title}><%= task_short_title(title) %></a></span>
      """
    else
      ~H"""
      <span><%= title %></span>
      """
    end
  end

  defp task_short_title(title), do: title |> String.split("/") |> List.last()
end

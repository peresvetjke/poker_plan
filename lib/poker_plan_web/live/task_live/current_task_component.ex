defmodule PokerPlanWeb.TaskLive.CurrentTaskComponent do
  use PokerPlanWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <br />

      <div class="rounded-lg border border-gray-400 p-4">
        <div class="mb-3">
          <span>Current task: </span>
          <.live_component
            id={"current-task-#{@current_task.task.id}"}
            module={PokerPlanWeb.TaskLive.TaskComponent}
            task={@current_task.task}
          >
          </.live_component>
        </div>

        <%= for i <- [1, 2, 3, 5, 8] do %>
          <button phx-click="estimate_task" phx-value-points={i} class={button_style(assigns, i)}>
            <%= i %>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def button_style(assigns, value) do
    if assigns.current_user.is_spectator do
      "button-style cursor-not-allowed"
    else
      pid = PokerPlan.CacheHelpers.pid(:task, assigns.current_task.task.id)

      case PokerPlan.Task.get_user_estimation(pid, assigns.current_user.id) do
        ^value -> "button-style-set"
        _ -> "button-style"
      end
    end
  end
end

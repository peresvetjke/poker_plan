defmodule PokerPlanWeb.RoundLive.FormComponent do
  use PokerPlanWeb, :live_component

  alias PokerPlan.Rounds

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage round records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="round-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Round</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{round: round} = assigns, socket) do
    changeset = Rounds.change_round(round)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"round" => round_params}, socket) do
    changeset =
      socket.assigns.round
      |> Rounds.change_round(round_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"round" => round_params}, socket) do
    save_round(socket, socket.assigns.action, round_params)
  end

  defp save_round(socket, :edit, round_params) do
    case Rounds.update_round(socket.assigns.round, round_params) do
      {:ok, round} ->
        # notify_parent({:saved, round})

        {:noreply,
         socket
         |> put_flash(:info, "Round updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_round(socket, :new, round_params) do
    case Rounds.create_round(round_params) do
      {:ok, round} ->
        # notify_parent({:saved, round})

        {:noreply,
         socket
         |> put_flash(:info, "Round created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

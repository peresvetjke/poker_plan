defmodule PokerPlan.Data.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  schema "users" do
    field(:username, :string)
    field(:is_spectator, :boolean)
    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, %{} = params \\ %{}) do
    user_or_changeset
    |> pow_changeset(params)
    |> pow_extension_changeset(params)
    |> Ecto.Changeset.cast(params, [:username, :is_spectator])
    |> Ecto.Changeset.validate_required([:username, :is_spectator])
  end
end

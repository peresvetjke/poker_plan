defmodule PokerPlan.Data.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  use PowAssent.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    # extensions: [PowResetPassword, PowEmailConfirmation]
    extensions: []

  schema "users" do
    has_many :user_identities,
             PokerPlan.Data.UserIdentity,
             on_delete: :delete_all,
             foreign_key: :user_id

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
  end
end

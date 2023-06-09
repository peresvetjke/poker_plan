defmodule PokerPlan.Data.UserIdentity do
  use Ecto.Schema
  use PowAssent.Ecto.UserIdentities.Schema, user: PokerPlan.Data.User

  schema "user_identities" do
    pow_assent_user_identity_fields()

    timestamps()
  end
end

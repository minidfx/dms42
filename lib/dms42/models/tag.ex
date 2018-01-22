defmodule Dms42.Models.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.Tag

  schema "tags" do
    field(:name, :string)
    field(:tag_id, Ecto.UUID)

    timestamps()
  end

  @doc false
  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:name, :tag_id])
    |> validate_required([:name, :tag_id])
    |> unique_constraint(:tag_id)
    |> unique_constraint(:name)
  end
end

defmodule Dms42.Models.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.Document

  schema "documents" do
    field :comments, :string
    field :document_id, :string

    timestamps()
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> cast(attrs, [:comments])
    |> validate_required([:comments])
  end
end

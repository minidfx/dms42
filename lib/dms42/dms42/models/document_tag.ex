defmodule Dms42.Models.DocumentTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.DocumentTag

  schema "documents_tags" do
    field :document_id, :string
    field :tag_id, :string

    timestamps()
  end

  @doc false
  def changeset(%DocumentTag{} = documentTag, attrs) do
    documentTag
    |> cast(attrs, [:document_id, :tag_id])
    |> validate_required([:document_id, :tag_id])
  end
end

defmodule Dms42.Models.DocumentTypeDocument do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.DocumentTypeDocument

  schema "documentTypeDocuments" do
    field :document_id, :binary
    field :document_type_id, :binary

    timestamps()
  end

  @doc false
  def changeset(%DocumentTypeDocument{} = documentTypeDocument, attrs) do
    documentTypeDocument
    |> cast(attrs, [:document_id, :document_type_id])
    |> validate_required([:document_id, :document_type_id])
  end
end

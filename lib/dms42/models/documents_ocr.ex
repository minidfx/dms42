defmodule Dms42.Models.DocumentsOcr do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.DocumentsOcr

  schema "documents_ocr" do
    field :document_id, :binary
    field :ocr, :string

    timestamps()
  end

  @doc false
  def changeset(%DocumentsOcr{} = documentOcr, attrs) do
    documentOcr
    |> cast(attrs, [:document_id, :ocr])
    |> validate_required([:document_id, :ocr])
  end
end

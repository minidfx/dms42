defmodule Dms42.Models.DocumentOcr do
  use Ecto.Schema

  import Ecto.Changeset

  alias Dms42.Models.DocumentOcr

  schema "documents_ocr" do
    field(:document_id, :binary)
    field(:ocr, :string)
    field(:ocr_normalized, :string)

    timestamps()
  end

  @doc false
  def changeset(%DocumentOcr{} = documentOcr, attrs) do
    documentOcr
    |> cast(attrs, [:document_id, :ocr, :ocr_normalized])
    |> validate_required([:document_id, :ocr, :ocr_normalized])
    |> foreign_key_constraint(:document_id)
  end
end

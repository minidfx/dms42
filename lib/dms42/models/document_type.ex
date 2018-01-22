defmodule Dms42.Models.DocumentType do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.DocumentType

  schema "documentTypes" do
    field(:name, :string)
    field(:document_type_id, Ecto.UUID)

    timestamps()
  end

  @doc false
  def changeset(%DocumentType{} = documentType, attrs) do
    documentType
    |> cast(attrs, [:name, :document_type_id])
    |> validate_required([:name, :document_type_id])
    |> unique_constraint(:document_type_id)
    |> unique_constraint(:name)
  end
end

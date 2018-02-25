defmodule Dms42.Models.DocumentType do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.DocumentType

  schema "document_types" do
    field(:name, :string)
    field(:type_id, :binary)

    timestamps()
  end

  @doc false
  def changeset(%DocumentType{} = documentType, attrs) do
    documentType
    |> cast(attrs, [:name, :type_id])
    |> validate_required([:name, :type_id])
    |> unique_constraint(:type_id)
    |> unique_constraint(:name)
  end
end

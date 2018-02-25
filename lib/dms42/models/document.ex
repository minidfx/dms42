defmodule Dms42.Models.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.Document

  schema "documents" do
    field(:comments, :string)
    field(:original_file_name, :string)
    field(:document_id, :binary)
    field(:mime_type, :string)
    field(:document_type_id, :binary)
    field(:original_file_datetime, :naive_datetime)
    field(:hash, :string)

    timestamps()
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> cast(attrs, [:comments, :original_file_name, :document_id, :mime_type, :hash, :document_type_id, :original_file_datetime])
    |> validate_required([:original_file_name, :document_id, :mime_type, :hash, :document_type_id, :original_file_datetime])
    |> unique_constraint(:document_id)
    |> foreign_key_constraint(:document_type_id)
  end
end

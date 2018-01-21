defmodule Dms42.Models.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.Document

  schema "documents" do
    field :comments, :string
    field :original_file_name, :string
    field :file_path, :string
    field :document_id, :binary
    field :mime_type, :string

    timestamps()
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> cast(attrs, [:comments, :original_file_name, :file_path, :document_id, :mime_type])
    |> validate_required([:original_file_name, :file_path, :document_id, :mime_type])
    |> unique_constraint(:file_path)
    |> unique_constraint(:document_id)
  end
end

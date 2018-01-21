defmodule Dms42.Models.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dms42.Models.Document

  schema "documents" do
    field :comments, :string
    field :original_file_name, :string
    field :file_path, :string
    field :document_id, :string

    timestamps()
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> cast(attrs, [:comments, :original_file_name, :file_path, :document_id, :ocr])
    |> validate_required([:original_file_name, :file_path, :document_id])
  end
end

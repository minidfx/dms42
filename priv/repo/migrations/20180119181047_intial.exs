defmodule Dms42.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :comments, :text
      add :document_id, :uuid
      add :original_file_name, :string
      add :file_path, :string

      timestamps()
    end

    create unique_index(:documents, :document_id)
    create unique_index(:documents, :file_path)

    create table(:tags) do
      add :name, :string, size: 32
      add :tag_id, :uuid

      timestamps()
    end

    create unique_index(:tags, :tag_id)

    create table(:documents_tags) do
      add :document_id, references(:documents, column: :document_id, type: :uuid)
      add :tag_id, references(:tags, column: :tag_id, type: :uuid)

      timestamps()
    end

    create table(:document_types) do
      add :name, :string
      add :document_type_id, :uuid

      timestamps()
    end

    create unique_index(:document_types, :document_type_id)

    create table(:document_type_documents) do
      add :document_id, references(:documents, column: :document_id, type: :uuid)
      add :document_type_id, references(:document_types, column: :document_type_id, type: :uuid)

      timestamps()
    end

    create table(:documents_ocr) do
      add :document_id, references(:documents, column: :document_id, type: :uuid)
      add :ocr, :string

      timestamps()
    end

  end
end

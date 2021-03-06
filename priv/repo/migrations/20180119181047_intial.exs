defmodule Dms42.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:document_types) do
      add :name, :string, null: false
      add :type_id, :uuid, null: false

      timestamps()
    end

    create unique_index(:document_types, :type_id)
    create unique_index(:document_types, :name)

    create table(:documents) do
      add :comments, :text
      add :document_id, :uuid, null: false
      add :original_file_name, :string, null: false
      add :original_file_name_normalized, :string, null: false
      add :mime_type, :string, null: false
      add :hash, :string, size: 64, null: false
      add :original_file_datetime, :naive_datetime, null: false
      add :document_type_id, references(:document_types, column: :type_id, type: :uuid), null: false

      timestamps()
    end

    create unique_index(:documents, :document_id)
    create unique_index(:documents, :hash)

    create table(:tags) do
      add :name, :string, size: 32, null: false
      add :name_normalized, :string, size: 32, null: false
      add :tag_id, :uuid, null: false

      timestamps()
    end

    create unique_index(:tags, :name)
    create unique_index(:tags, :name_normalized)
    create unique_index(:tags, :tag_id)

    create table(:documents_tags) do
      add :document_id, references(:documents, column: :document_id, type: :uuid), null: false
      add :tag_id, references(:tags, column: :tag_id, type: :uuid), null: false

      timestamps()
    end

    create unique_index(:documents_tags, [:tag_id, :document_id])

    create table(:documents_ocr) do
      add :document_id, references(:documents, column: :document_id, type: :uuid), null: false
      add :ocr, :text, null: false
      add :ocr_normalized, :text, null: false

      timestamps()
    end

    create unique_index(:documents_ocr, :document_id)
  end
end

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
      add :file_path, :string, null: false
      add :mime_type, :string, null: false
      add :hash, :string, size: 64, null: false
      add :document_type_id, references(:document_types, column: :type_id, type: :uuid), null: false

      timestamps()
    end

    create unique_index(:documents, :document_id)
    create unique_index(:documents, :file_path)
    create unique_index(:documents, :hash)

    create table(:tags) do
      add :name, :string, size: 32, null: false
      add :tag_id, :uuid, null: false

      timestamps()
    end

    create unique_index(:tags, :name)
    create unique_index(:tags, :tag_id)

    create table(:documents_tags) do
      add :document_id, references(:documents, column: :document_id, type: :uuid)
      add :tag_id, references(:tags, column: :tag_id, type: :uuid)

      timestamps()
    end

    create table(:documents_ocr) do
      add :document_id, references(:documents, column: :document_id, type: :uuid)
      add :ocr, :string, null: true

      timestamps()
    end
  end
end

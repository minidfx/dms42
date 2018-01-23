defmodule Dms42.Repo.Migrations.DefaultEntries do
  use Ecto.Migration
  alias Dms42.Models.DocumentType

  def change do
    Dms42.Repo.insert(DocumentType.changeset(%DocumentType{}, %{name: "Default", type_id: <<145, 210, 233, 14, 217, 108, 79, 81, 159, 234, 128, 47, 152, 115, 193, 187>>}))
    Dms42.Repo.insert(DocumentType.changeset(%DocumentType{}, %{name: "Bill", type_id: <<33, 201, 95, 93, 74, 177, 74, 4, 169, 44, 181, 106, 78, 161, 166, 35>>}))
  end
end

defmodule Dms42.Documents do
  import Ecto.Query

  alias Dms42.Models.Document
  alias Dms42.Models.Tag
  alias Dms42.TagManager
  alias Dms42.DocumentPath

  require Logger

  @spec documents(offset :: integer, length :: integer) :: list(map)
  def documents(offset, length) do
    documents = Document |> limit(^length)
                         |> offset(^offset)
                         |> order_by(asc: :inserted_at)
                         |> Dms42.Repo.all
                         |> transform_to_viewmodels
  end

  @spec transform_to_viewmodels(list(Documents)) :: list(map)
  def transform_to_viewmodels(documents), do: documents |> Enum.map(&transform_to_viewmodel/1)

  @spec transform_to_viewmodel(Document) :: map
  def transform_to_viewmodel(%Document{:document_id => did} = document) do
    document = Map.put(document,
                       :tags,
                       TagManager.get_tags(did) |> Enum.map(fn %Tag{:name => tag} -> tag end))
    %{ :comments => comments,
       :document_id => did,
       :document_type_id => doc_type_id,
       :inserted_at => inserted,
       :updated_at => updated,
       :tags => tags,
       :original_file_datetime => original_file_datetime,
       :original_file_name => original_file_name
      } = document
      images = DocumentPath.big_thumbnail_paths!(document)
      {:ok, document_id_string} = Ecto.UUID.load(did)
      {:ok, document_type_id_string} = Ecto.UUID.load(doc_type_id)
      IO.inspect updated
      datetimes = case updated do
                    nil -> %{
                            "inserted_datetime" => inserted |> to_rfc2822,
                            "original_file_datetime" => original_file_datetime |> to_rfc2822
                          }
                    x -> %{
                      "inserted_datetime" => inserted |> to_rfc2822,
                      "updated_datetime" => updated |> to_rfc2822,
                      "original_file_datetime" => original_file_datetime |> to_rfc2822
                    }
                  end
      %{
        "datetimes" => datetimes,
        "comments" => comments |> null_to_string,
        "document_id" => document_id_string,
        "document_type_id" => document_type_id_string,
        "tags" => tags,
        "original_file_name" => original_file_name,
        "count_images" => images |> Enum.count
      }
  end

  @spec to_rfc2822(Timex.Types.valid_datetime()) :: String.t()
  def to_rfc2822(datetime) do
    {:ok, x} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    x
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string
end

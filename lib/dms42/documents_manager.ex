defmodule Dms42.DocumentsManager do

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.Tag

  alias Dms42.TagManager
  alias Dms42.TransactionHelper
  alias Dms42.DocumentPath

  import Ecto.Query

  @doc """
    Add the document processing the OCR and saving it.
  """
  @spec add(file_name :: String.t(), mime_type :: String.t(), original_file_datetime :: DateTime.t(), document_type :: String.t(), tags :: list(String.t()), bytes :: binary) :: :ok | {:error, reason :: String.t()}
  def add(file_name, mime_type, original_file_datetime, document_type, tags, bytes) do
    GenServer.call(:documents_processor, {:process,
                                          file_name,
                                          mime_type,
                                          original_file_datetime,
                                          document_type,
                                          tags,
                                          bytes})
  end

  @doc """
    Removes the document from the database, the storage and its associated data.
  """
  @spec remove!(document_id :: binary) :: no_return()
  def remove!(document_id) do
    document = Document |> Dms42.Repo.get_by!(document_id: document_id)
    document_path = DocumentPath.document_path!(document)
    temp_file_path = Temp.path!
    File.rename(document_path, temp_file_path)
    try do
      Ecto.Multi.new() |> TagManager.clean_document_tags(document_id)
                       |> Ecto.Multi.delete_all("delete_ocr", (from DocumentOcr, where: [document_id: ^document_id]))
                       |> Ecto.Multi.delete("delete_document", document)
                       |> TransactionHelper.commit!
      File.rm!(temp_file_path)
    rescue
      e ->
        File.rename(temp_file_path, document_path)
        IO.inspect(e)
    end
  end

  @doc """
    Edits the document comments.
  """
  @spec edit_comments!(document_id :: String.t(), comments :: String.t()) :: Document
  def edit_comments!(document_id, comments) do
    {:ok, uuid} = Ecto.UUID.dump(document_id)
    case Dms42.Repo.get_by(Document, document_id: uuid) do
      nil -> raise("Document #{document_id} not found")
      x ->
        Dms42.Repo.update!(Document.changeset(x, %{comments: comments |> empty_to_null}))
    end
  end

  @spec documents(offset :: integer, length :: integer) :: list(map)
  def documents(offset, length) do
    Document |> limit(^length)
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
                      "updated_datetime" => x |> to_rfc2822,
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
        "thumbnails" => %{ "count-images": images |> Enum.count }
      }
  end

  @spec to_rfc2822(Timex.Types.valid_datetime()) :: String.t()
  def to_rfc2822(datetime) do
    {:ok, x} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    x
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp empty_to_null(string), do: string
  defp empty_to_null(""), do: nil

end
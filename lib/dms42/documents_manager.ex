defmodule Dms42.DocumentsManager do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.Tag
  alias Dms42.Models.SearchResult

  alias Dms42.TagManager
  alias Dms42.TransactionHelper
  alias Dms42.DocumentPath

  alias Dms42.MapHelper

  import Ecto.Query

  @doc """
    Add the document processing the OCR and saving it.
  """
  def add(file_name, mime_type, original_file_datetime, document_type, tags, bytes) do
    Dms42.QueueDocuments.enqueue_document(
      file_name,
      mime_type,
      original_file_datetime,
      document_type,
      tags,
      bytes
    )
  end

  @spec generate_thumbnails() :: :ok
  def generate_thumbnails() do
    Document
    |> Dms42.Repo.all()
    |> Enum.each(&Dms42.QueueDocuments.enqueue_thumbnail/1)

    :ok
  end

  @spec generate_ocrs() :: :ok
  def generate_ocrs() do
    Document
    |> Dms42.Repo.all()
    |> Enum.each(&Dms42.QueueDocuments.enqueue_ocr/1)

    :ok
  end

  @doc """
    Removes the document from the database, the storage and its associated data.
  """
  def remove!(document_ids) when is_list(document_ids),
    do: remove!(document_ids, Ecto.Multi.new())

  def remove!(document_id),
    do: remove!([document_id], Ecto.Multi.new())

  @doc """
    Edits the document comments.
  """
  def edit_comments!(document_id, comments) do
    case Dms42.Repo.get_by(Document, document_id: document_id) do
      nil ->
        {:ok, uuid} = Ecto.UUID.load(document_id)
        raise("Document #{uuid} not found")

      x ->
        Dms42.Repo.update!(Document.changeset(x, %{comments: comments |> empty_to_null}))
    end
  end

  def documents(offset, length) do
    Document
    |> limit(^length)
    |> offset(^offset)
    |> order_by(desc: :inserted_at)
    |> Dms42.Repo.all()
    |> transform_to_viewmodels
  end

  def count() do
    [head | _] = from(d in Document, select: count(d.id)) |> Dms42.Repo.all()
    head
  end

  def ocr(document_ids) do
    DocumentOcr
    |> where([x], x.document_id in ^document_ids)
    |> Dms42.Repo.all()
  end

  @doc """
    Gets the document view model with the given document_id passed as argument.
  """
  def get(document_id) when is_binary(document_id) do
    Document |> Dms42.Repo.get_by!(document_id: document_id) |> transform_to_viewmodel
  end

  def get_original!(document_id) when is_binary(document_id),
    do: Document |> Dms42.Repo.get_by!(document_id: document_id)

  def transform_to_viewmodels(documents), do: documents |> Enum.map(&transform_to_viewmodel/1)

  def transform_to_viewmodel(%SearchResult{:document => document, :ranking => ranking}),
    do: transform_to_viewmodel(document, ranking: ranking)

  def transform_to_viewmodel(%Document{:document_id => did} = document, additional_props \\ []) do
    document =
      Map.put(
        document,
        :tags,
        TagManager.get_tags(did) |> Enum.map(fn %Tag{:name => tag} -> tag end)
      )

    %{
      :comments => comments,
      :document_id => did,
      :inserted_at => inserted,
      :updated_at => updated,
      :tags => tags,
      :original_file_datetime => original_file_datetime,
      :original_file_name => original_file_name
    } = document

    images = DocumentPath.big_thumbnail_paths!(document)

    {:ok, document_id_string} = Ecto.UUID.load(did)

    datetimes =
      %{
        "inserted_datetime" => inserted |> to_iso8601,
        "original_file_datetime" => original_file_datetime |> to_iso8601
      }
      |> MapHelper.put_if("updated_datetime", fn -> updated |> to_iso8601 end, updated != nil)

    document_ocr = DocumentOcr |> Dms42.Repo.get_by(document_id: did)

    document = %{
      "datetimes" => datetimes,
      "comments" => comments |> null_to_string,
      "document_id" => document_id_string,
      "tags" => tags,
      "original_file_name" => original_file_name,
      "thumbnails" => %{"count-images": images |> Enum.count()}
    }

    document =
      document
      |> MapHelper.put_if(
        :ocr,
        fn ->
          %DocumentOcr{:ocr => ocr} = document_ocr
          ocr
        end,
        document_ocr != nil
      )

    additional_props |> Enum.reduce(document, fn {k, v}, d -> Map.put_new(d, k, v) end)
  end

  def to_iso8601(datetime) do
    Timex.format!(datetime, "{ISO:Extended:Z}")
  end

  def is_document_exists?(bytes) do
    {result, _} = is_document_exists(bytes)
    result
  end

  def is_document_exists(bytes) do
    hash = :crypto.hash(:sha256, bytes) |> Base.encode16()

    case Dms42.Repo.get_by(Document, hash: hash) do
      nil -> {false, hash}
      _ -> {true, hash}
    end
  end

  defp remove!(document_ids, transaction) do
    {transaction, documents} =
      Enum.reduce(
        document_ids,
        {transaction, []},
        fn x, acc ->
          {local_transaction, documents} = acc
          document = Document |> Dms42.Repo.get_by!(document_id: x)

          local_transaction =
            local_transaction
            |> TagManager.clean_document_tags(x)
            |> Ecto.Multi.delete_all("delete_ocr", from(DocumentOcr, where: [document_id: ^x]))
            |> Ecto.Multi.delete("delete_document", document)

          {local_transaction, [document | documents]}
        end
      )

    transaction |> TransactionHelper.commit!()

    Enum.each(
      documents,
      fn x ->
        DocumentPath.document_path!(x) |> File.rm!()
      end
    )

    :ok
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp empty_to_null(""), do: nil
  defp empty_to_null(string), do: string
end

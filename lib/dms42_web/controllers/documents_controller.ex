defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentType
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.Tag
  alias Dms42.DocumentPath
  alias Dms42.TagManager
  alias Dms42.DocumentManager

  import Ecto.Query

  @doc false
  def upload_documents(conn, %{
        "file" => %{
          :content_type => mime_type,
          :filename => original_file_name,
          :path => temp_file_path
        },
        "tags" => tags,
        "document_type" => document_type,
        "fileUnixTimestamp" => file_timestamp
      }) do
    GenServer.cast(
      :documents_processor,
      {:process, original_file_name, mime_type, file_timestamp |> String.to_integer |> Timex.from_unix(:milliseconds), document_type,
       tags |> String.split(",", trim: true), File.read!(temp_file_path)}
    )

    conn |> send_resp(200, "")
  end

  @doc false
  def upload_documents(conn, _params) do
    conn |> send_resp(400, "")
  end

  @doc false
  def thumbnail(conn, %{"document_id" => document_id}) do
    case Ecto.UUID.dump(document_id) do
      :error -> conn |> send_resp(400, %{reason: "The document_id is not a valid uuid."} |> Poison.encode!)
      {:ok, uuid} -> document = Dms42.Repo.get_by(Document, document_id: uuid)
                     absolute_file_path = DocumentPath.small_thumbnail_path!(document)
                     conn
                     |> put_resp_content_type("image/png")
                     |> send_file(200, absolute_file_path)
    end
  end

  @doc false
  def document(conn, %{"document_id" => document_id}) do
    case Ecto.UUID.dump(document_id) do
      :error -> conn |> send_resp(400, %{reason: "The document_id is not a valid uuid."} |> Poison.encode!)
      {:ok, uuid} -> document = Dms42.Repo.get_by(Document, document_id: uuid)
                     [absolute_file_path] = DocumentPath.big_thumbnail_paths!(document) |> Enum.take(1)
                     case File.exists?(absolute_file_path) do
                       false ->
                         conn
                         |> put_status(404)

                       true ->
                         conn
                         |> put_resp_content_type("image/png")
                         |> send_file(200, absolute_file_path)
                    end
    end
  end

  @doc false
  def documents(conn, %{"start" => start, "length" => length}) do
    documents = Document |> join(:left, [d], o in DocumentOcr, o.document_id == d.document_id)
                         |> limit(^length)
                         |> offset(^start)
                         |> order_by([d], asc: :inserted_at)
                         |> select([d, o], {d, o.ocr})
                         |> Dms42.Repo.all
                         |> Enum.map(fn {%{:document_id => d_id} = document, ocr} ->
                              Map.put(document,
                                      :tags,
                                      TagManager.get_tags(d_id) |> Enum.map(fn %Tag{:name => tag} -> tag end))
                              |> Map.put(:ocr, ocr)
                         end)
                         |> Enum.map(fn %{  :comments => comments,
                                            :document_id => d_id,
                                            :document_type_id => doc_type_id,
                                            :inserted_at => inserted,
                                            :updated_at => updated,
                                            :tags => tags,
                                            :original_file_datetime => original_file_datetime,
                                            :original_file_name => original_file_name,
                                            :ocr => ocr
                                          } ->
        {:ok, document_id_string} = Ecto.UUID.load(d_id)
        {:ok, document_type_id_string} = Ecto.UUID.load(doc_type_id)
        %{
          "datetimes" => %{
            "inserted_datetime" => inserted |> to_rfc2822,
            "updated_datetime" => updated |> to_rfc2822,
            "original_file_datetime" => original_file_datetime |> to_rfc2822
          },
          "comments" => comments |> null_to_string,
          "document_id" => document_id_string,
          "document_type_id" => document_type_id_string,
          "tags" => tags,
          "original_file_name" => original_file_name,
          "ocr" => ocr |> null_to_string
        }
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, documents |> Poison.encode!)
  end

  @doc false
  def document_types(conn, _params) do
    document_types =
      DocumentType
      |> Dms42.Repo.all
      |> Enum.map(fn %{:name => name, :type_id => type_id} ->
        {:ok, uuid} = Ecto.UUID.load(type_id)
        %{"name" => name, "id" => uuid}
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, document_types |> Poison.encode!)
  end

  @doc false
  def create_tag(conn, %{"document_id" => document_id, "tag" => tag}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump
    TagManager.add_or_update!(binary_document_id, tag)
    conn |> send_resp(200, "")
  end

  @doc false
  def delete_tag(conn, %{"document_id" => document_id, "tag" => tag}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump
    TagManager.remove!(binary_document_id, tag)
    conn |> send_resp(200, %{document_id: document_id, tag: tag} |> Poison.encode!)
  end

  @doc false
  def delete_document(conn, %{"document_id" => document_id}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump
    DocumentManager.remove!(binary_document_id)
    conn |> send_resp(200, %{document_id: document_id} |> Poison.encode!)
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp to_rfc2822(datetime) do
    {:ok, rfc2822} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    rfc2822
  end
end

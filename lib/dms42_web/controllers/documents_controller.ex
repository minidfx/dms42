defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentType
  alias Dms42.Models.Tag
  alias Dms42.DocumentPath
  alias Dms42.TagManager
  alias Dms42.DocumentManager
  alias Dms42.DocumentsFinder
  alias Dms42.DocumentsProcessor

  import Ecto.Query

  require Logger

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
    bytes = File.read!(temp_file_path)
    case DocumentsProcessor.is_document_exists?(bytes) do
      :true ->
        conn |> put_resp_content_type("text/plain")
             |> send_resp(400, "The document already exists")
      :false ->
        GenServer.cast(:documents_processor,
                       {:process,
                       original_file_name,
                       mime_type,
                       file_timestamp |> String.to_integer |> Timex.from_unix(:milliseconds),
                       document_type,
                       tags |> String.split(",", trim: true),
                       bytes})
        conn |> send_resp(200, "")
    end
  end
  def upload_documents(conn, _params), do: conn |> send_resp(400, "Argument not recognized.")

  @doc false
  def thumbnail(conn, %{"document_id" => document_id}) do
    case valid_document_query(conn, document_id) do
      {:error, conn} -> conn
      {:ok, conn, document} -> absolute_file_path = DocumentPath.small_thumbnail_path!(document)
                               conn |> put_resp_content_type("image/png")
                                    |> send_file(200, absolute_file_path)
    end
  end

  @doc false
  def document_image(conn, %{"document_id" => document_id, "image_id" => image_id}) do
    case valid_document_query(conn, document_id) do
      {:error, conn} -> conn
      {:ok, conn, document} ->
        path = DocumentPath.big_thumbnail_paths!(document) |> Enum.at(image_id |> String.to_integer)
        IO.inspect(path)
        case path do
          nil -> conn |> send_resp(404, "")
          x ->
            case File.exists?(x) do
              false -> conn |> send_resp(404, "")
              true -> conn |> put_resp_content_type("image/png")
                           |> send_file(200, x)
            end
        end
    end
  end

  @doc false
  def document_image(conn, %{"document_id" => document_id}) do
    case valid_document_query(conn, document_id) do
      {:error, conn} -> conn
      {:ok, conn, document} -> [absolute_file_path] = DocumentPath.big_thumbnail_paths!(document) |> Enum.take(1)
                                case File.exists?(absolute_file_path) do
                                  false -> conn |> put_status(404)
                                  true ->
                                    conn |> put_resp_content_type("image/png")
                                         |> send_file(200, absolute_file_path)
                                end
    end
  end

  @doc false
  def document(conn, %{"document_id" => document_id}) do
    case valid_document_query(conn, document_id) do
      {:error, conn} -> conn
      {:ok, conn, document} -> conn |> put_resp_content_type("application/json")
                                    |> send_resp(200, document |> transform_to_viewmodel
                                                               |> Poison.encode!)
    end
  end

  @doc false
  def documents(conn, %{"start" => start, "length" => length}) do
    documents = Document |> limit(^length)
                         |> offset(^start)
                         |> order_by(asc: :inserted_at)
                         |> Dms42.Repo.all
                         |> transform_to_viewmodels
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, documents |> Poison.encode!)
  end
  def documents(conn, %{"query" => query}) do
    conn |> put_resp_content_type("application/json")
         |> send_resp(200, DocumentsFinder.find(query) |> transform_to_viewmodels |> Poison.encode!)
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

  defp valid_document_query(conn, document_id) do
    case Ecto.UUID.dump(document_id) do
      :error -> {:error, conn |> put_resp_content_type("text/plain")
                              |> send_resp(400, "The given UUID is invalid: document_id")}
      {:ok, uuid} -> case Dms42.Repo.get_by(Document, document_id: uuid) do
                      nil -> {:error, conn |> put_resp_content_type("text/plain")
                                           |> send_resp(404, "The given UUID is not found: #{uuid}")}
                      x -> {:ok, conn, x}
                     end
    end
  end

  defp transform_to_viewmodels(documents), do: documents |> Enum.map(&transform_to_viewmodel/1)
  defp transform_to_viewmodel(%Document{:document_id => did} = document) do
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
        "count_images" => images |> Enum.count
      }
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp to_rfc2822(datetime) do
    {:ok, rfc2822} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    rfc2822
  end
end

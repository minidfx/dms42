defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentType
  alias Dms42.DocumentPath
  alias Dms42.TagManager
  alias Dms42.DocumentsManager
  alias Dms42.DocumentsFinder

  require Logger

  @doc false
  def upload_documents(conn, %{
        "file" => %{
          :content_type => mime_type,
          :filename => original_file_name,
          :path => temp_file_path
        },
        "tags" => tags,
        "fileUnixTimestamp" => file_timestamp
      }) do
    bytes = File.read!(temp_file_path)

    case DocumentsManager.is_document_exists?(bytes) do
      true ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(400, "The document already exists")

      false ->
        DocumentsManager.add(
          original_file_name,
          mime_type,
          file_timestamp |> String.to_integer() |> Timex.from_unix(:milliseconds),
          "91d2e90e-d96c-4f51-9fea-802f9873c1bb",
          tags |> String.split(",", trim: true),
          bytes
        )

        conn |> send_resp(200, "")
    end
  end

  def upload_documents(conn, _params), do: conn |> send_resp(400, "Argument not recognized.")

  @doc false
  def download(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn |> send_resp(404, "")

      {:ok, conn, document} ->
        %{:mime_type => mime_type, :original_file_name => filename} = document
        documentPath = DocumentPath.document_path!(document)

        conn
        |> put_resp_content_type(mime_type)
        |> put_resp_header("Content-Disposition", "attachment; filename=\"#{filename}\"")
        |> send_file(200, documentPath)
    end
  end

  @doc false
  def thumbnail(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        absolute_file_path =
          DocumentPath.small_thumbnail_path!(document)
          |> small_thumbnail_fallback_whether_no_exists(conn)
    end
  end

  def process_ocr(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        Dms42.QueueDocuments.enqueue_ocr(document)
        conn |> send_resp(200, "")
    end
  end

  def process_thumbnails(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        Dms42.QueueDocuments.enqueue_thumbnail(document)
        conn |> send_resp(200, "")
    end
  end

  @doc false
  def document_image(conn, %{"document_id" => document_id, "image_id" => image_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        path =
          DocumentPath.big_thumbnail_paths!(document)
          |> Enum.at(image_id |> String.to_integer())
          |> big_thumbnail_fallback_whether_no_exists(conn)
    end
  end

  @doc false
  def document_image(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        absolute_file_path =
          DocumentPath.big_thumbnail_paths!(document)
          |> Enum.take(1)
          |> Enum.at(0)
          |> big_thumbnail_fallback_whether_no_exists(conn)
    end
  end

  @doc false
  def document(conn, %{"document_id" => document_id}) do
    case get_document(conn, document_id) do
      {:error, conn} ->
        conn

      {:ok, conn, document} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          document
          |> DocumentsManager.transform_to_viewmodel()
          |> Poison.encode!()
        )
    end
  end

  @doc false
  def documents(conn, %{"offset" => offset, "length" => length}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      %{documents: DocumentsManager.documents(offset, length), total: DocumentsManager.count()}
      |> Poison.encode!()
    )
  end

  def documents(conn, %{"query" => query}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      DocumentsFinder.find(query)
      |> DocumentsManager.transform_to_viewmodels()
      |> Poison.encode!()
    )
  end

  @doc false
  def document_types(conn, _params) do
    document_types =
      DocumentType
      |> Dms42.Repo.all()
      |> Enum.map(fn %{:name => name, :type_id => type_id} ->
        {:ok, uuid} = Ecto.UUID.load(type_id)
        %{"name" => name, "id" => uuid}
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, document_types |> Poison.encode!())
  end

  @doc false
  def create_tag(conn, %{"document_id" => document_id, "tag" => tag}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump()
    TagManager.add_or_update!(binary_document_id, tag)
    conn |> send_resp(200, "")
  end

  @doc false
  def delete_tag(conn, %{"document_id" => document_id, "tag" => tag}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump()
    TagManager.remove!(binary_document_id, tag)
    conn |> send_resp(200, %{document_id: document_id, tag: tag} |> Poison.encode!())
  end

  @doc false
  def delete_document(conn, %{"document_id" => document_id}) do
    {:ok, binary_document_id} = document_id |> Ecto.UUID.dump()
    DocumentsManager.remove!(binary_document_id)
    conn |> send_resp(200, %{document_id: document_id} |> Poison.encode!())
  end

  ##### Private members

  @spec thumbnail_fallback_whether_no_exists(nil, Plug.Conn.t(), String.t()) :: String.t()
  defp thumbnail_fallback_whether_no_exists(nil, conn, fallback_path),
    do: Path.absname(fallback_path)

  @spec thumbnail_fallback_whether_no_exists(String.t(), Plug.Conn.t(), String.t()) ::
          Plug.Conn.t()
  defp thumbnail_fallback_whether_no_exists(path, conn, fallback_path) do
    case File.exists?(path) do
      true ->
        conn
        |> put_resp_content_type("image/png")
        |> send_file(200, path)

      false ->
        conn
        |> update_resp_header("cache-control", "no-cache", fn _ -> "no-cache" end)
        |> put_resp_content_type("image/png")
        |> send_file(404, fallback_path)
    end
  end

  @spec big_thumbnail_fallback_whether_no_exists(String.t(), Plug.Conn.t()) :: Plug.Conn.t()
  defp big_thumbnail_fallback_whether_no_exists(path, conn),
    do:
      thumbnail_fallback_whether_no_exists(path, conn, "priv/static/images/big_thumbnail_404.png")

  @spec small_thumbnail_fallback_whether_no_exists(String.t(), Plug.Conn.t()) :: Plug.Conn.t()
  defp small_thumbnail_fallback_whether_no_exists(path, conn),
    do:
      thumbnail_fallback_whether_no_exists(
        path,
        conn,
        "priv/static/images/small_thumbnail_404.png"
      )

  defp get_document(conn, document_id) do
    case Ecto.UUID.dump(document_id) do
      :error ->
        {:error,
         conn
         |> put_resp_content_type("text/plain")
         |> send_resp(400, "The given UUID is invalid: document_id")}

      {:ok, uuid} ->
        case Dms42.Repo.get_by(Document, document_id: uuid) do
          nil ->
            {:error,
             conn
             |> put_resp_content_type("text/plain")
             |> send_resp(404, "The given UUID is not found: #{uuid}")}

          x ->
            {:ok, conn, x}
        end
    end
  end
end

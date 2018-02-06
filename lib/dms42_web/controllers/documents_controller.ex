defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.DocumentsManager
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentType
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag

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
    case DocumentsManager.add(
           original_file_name,
           mime_type,
           file_timestamp |> String.to_integer |> Timex.from_unix(:milliseconds),
           document_type,
           tags |> String.split(",", trim: true),
           File.read!(temp_file_path)
         ) do
      {:error, reason} -> conn |> error_plain_text(reason)
      {:ok, _document} -> conn |> send_resp(200, "")
    end
  end

  @doc false
  def upload_documents(conn, _params) do
    conn |> send_resp(400, "")
  end

  def thumbnail(conn, %{"document_id" => document_id}) do
    %{:file_path => relative_file_path} = Dms42.Repo.get_by(Document, document_id: document_id)
    base_thumbnails_path = Application.get_env(:dms42, :thumbnails_path) |> Path.absname()
    absolute_file_path = Path.join(base_thumbnails_path, relative_file_path <> "_small")

    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, absolute_file_path)
  end

  def document(conn, %{"document_id" => document_id}) do
    query = from Document,
            where: [document_id: ^document_id],
            select: [:file_path]
    %{:file_path => relative_file_path} = query |> Dms42.Repo.one
    base_thumbnails_path = Application.get_env(:dms42, :thumbnails_path) |> Path.absname()
    absolute_file_path = Path.join(base_thumbnails_path, relative_file_path <> "_big")

    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, absolute_file_path)
  end

  @doc false
  def documents(conn, %{"start" => start, "length" => length}) do
    documents =
      from(d in Document, limit: ^length, offset: ^start, order_by: d.inserted_at)
      |> Dms42.Repo.all()
      |> Enum.map(fn %{:document_id => d_id} = document -> Map.put(document, :tags, tags(d_id)) end)
      |> Enum.map(fn %{
                       :comments => comments,
                       :document_id => d_id,
                       :document_type_id => doc_type_id,
                       :inserted_at => inserted,
                       :updated_at => updated,
                       :file_path => file_path,
                       :tags => tags
                     } ->
        %{
          "insertedAt" => inserted |> to_rfc2822,
          "updatedAt" => updated |> to_rfc2822,
          "thumbnailPath" => file_path |> transform_to_frontend_url,
          "comments" => comments |> null_to_string,
          "document_id" => d_id,
          "document_type_id" => doc_type_id,
          "tags" => tags
        }
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, documents |> Poison.encode!)
  end

  def document_types(conn, _params) do
    document_types =
      DocumentType
      |> Dms42.Repo.all()
      |> Enum.map(fn %{:name => name, :type_id => type_id} -> %{"name" => name, "id" => type_id} end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, document_types |> Poison.encode!)
  end

  @spec tags(document_id :: integer) :: list(String.t)
  defp tags(document_id) do
    query = from dt in DocumentTag,
            join: t in Tag,
            on: [tag_id: dt.tag_id],
            where: [document_id: ^document_id],
            order_by: [dt.inserted_at],
            select: t.name
    query |> Dms42.Repo.all
  end

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp transform_to_frontend_url(path), do: "/images/thumbnails/#{path}"

  defp to_rfc2822(datetime) do
    {:ok, rfc2822} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    rfc2822
  end

  @spec error_plain_text(connection :: Plug.Conn, reason :: String.t()) :: no_return
  defp error_plain_text(conn, reason) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, reason)
  end
end

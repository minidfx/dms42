defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.DocumentsManager
  alias Dms42.Models.Document

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
    absolute_file_path = Path.join(base_thumbnails_path, relative_file_path)

    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, absolute_file_path)
  end

  @spec error_plain_text(connection :: Plug.Conn, reason :: String.t()) :: no_return
  defp error_plain_text(conn, reason) do
    conn |> put_resp_content_type("text/plain")
    |> send_resp(400, reason)
  end
end

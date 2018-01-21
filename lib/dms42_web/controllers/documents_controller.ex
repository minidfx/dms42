defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.DocumentManager

  @doc false
  def upload_documents(conn, %{"file" => %{:content_type => mime_type, :filename => original_file_name, :path => temp_file_path}}) do
    case DocumentManager.add(mime_type, original_file_name, File.read!(temp_file_path)) do
      {:error, reason} -> conn |> error_plain_text(reason)
      {:ok, _document} -> conn |> send_resp(200, "")
    end
  end
  @doc false
  def upload_documents(conn, _params) do
    conn |> send_resp(400, "")
  end

  @spec error_plain_text(connection :: Plug.Conn, reason :: String.t) :: no_return
  defp error_plain_text(conn, reason) do
    conn |> put_resp_content_type("text/plain")
         |> send_resp(400, reason)
  end
end

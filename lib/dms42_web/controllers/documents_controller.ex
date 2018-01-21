defmodule Dms42Web.DocumentsController do
  use Dms42Web, :controller

  alias Dms42.DocumentManager

  @doc false
  def upload_documents(conn, %{"file" => %{:content_type => content_type, :filename => original_file_name, :path => temp_file_path}}) do
    DocumentManager.add(original_file_name, File.read!(temp_file_path))
    conn |> send_resp(200, "")
  end
  @doc false
  def upload_documents(conn, _params) do
    conn |> send_resp(400, "")
  end
end

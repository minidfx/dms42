defmodule Dms42Web.SettingsController do
  use Dms42Web, :controller

  require Logger

  alias Dms42.DocumentsManager

  def process_all_thumbnails(conn, _) do
    DocumentsManager.generate_thumbnails()

    conn
    |> send_resp(200, "")
  end

  def process_all_ocrs(conn, _) do
    DocumentsManager.generate_ocrs()

    conn
    |> send_resp(200, "")
  end

  def get_queue_info(conn, _) do
    queue_info = Dms42.QueueDocuments.info()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, queue_info |> Poison.encode!())
  end
end

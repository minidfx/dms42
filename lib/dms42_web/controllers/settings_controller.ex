defmodule Dms42Web.SettingsController do
  use Dms42Web, :controller

  require Logger

  alias Dms42.DocumentsManager

  def process_all_thumbnails(conn, _) do
    DocumentsManager.generate_thumbnails()
    conn |> send_resp(200, "")
  end
end

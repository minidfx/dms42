defmodule Dms42Web.TagController do
  use Dms42Web, :controller

  alias Dms42.TagManager

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      TagManager.get_tags()
      |> Enum.map(fn %{:name => name} -> name end)
      |> Poison.encode!()
    )
  end

  def update(conn, %{"old_tag_name" => old_name, "new_tag_name" => new_name}) do
    TagManager.update!(old_name, new_name)
    conn |> put_status(200)
  end
end

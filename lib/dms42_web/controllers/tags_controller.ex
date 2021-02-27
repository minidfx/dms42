defmodule Dms42Web.TagsController do
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

  def update(conn, %{"oldTag" => old_name, "newTag" => new_name}) do
    try do
      TagManager.update!(old_name, new_name)
      conn |> send_resp(200, %{newTag: new_name} |> Poison.encode!())
    rescue
      e in RuntimeError ->
        %{:message => reason} = e
        conn |> send_resp(400, reason)
    end
  end
end

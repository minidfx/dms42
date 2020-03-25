defmodule Dms42Web.PageController do
  use Dms42Web, :controller

  def index(conn, _params) do
    conn
    |> update_resp_header("cache-control", "no-cache", fn _ -> "no-cache" end)
    |> render("index.html")
  end
end

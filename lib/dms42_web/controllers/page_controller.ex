defmodule Dms42Web.PageController do
  use Dms42Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule Dms42Web.Router do
  use Dms42Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Dms42Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/documents/thumbnail/:document_id", DocumentsController, :thumbnail)
  end

  # Other scopes may use custom stacks.
  scope "/api", Dms42Web do
    pipe_through(:api)

    get("/documents", DocumentsController, :documents)
    get("/document-types", DocumentsController, :document_types)
    post("/documents", DocumentsController, :upload_documents)
  end
end

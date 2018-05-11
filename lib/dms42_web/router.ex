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
    get("/documents/:document_id/image", DocumentsController, :document_image)
  end

  # Other scopes may use custom stacks.
  scope "/api", Dms42Web do
    pipe_through(:api)

    get("/documents", DocumentsController, :documents)
    get("/documents/:document_id", DocumentsController, :document)
    get("/document-types", DocumentsController, :document_types)
    get("/tags", TagController, :index)

    post("/documents", DocumentsController, :upload_documents)
    post("/documents/:document_id/tags/:tag", DocumentsController, :create_tag)
    post("/tags", TagController, :update)

    delete("/documents/:document_id/tags/:tag", DocumentsController, :delete_tag)
    delete("/documents/:document_id", DocumentsController, :delete_document)
  end
end

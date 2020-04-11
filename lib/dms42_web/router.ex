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

  # Other scopes may use custom stacks.
  scope "/api", Dms42Web do
    pipe_through(:api)

    get("/documents/:document_id", DocumentsController, :document)
    get("/documents/:document_id/download", DocumentsController, :download)
    delete("/documents/:document_id", DocumentsController, :delete_document)
    post("/documents/:document_id/ocr", DocumentsController, :process_ocr)
    post("/documents/:document_id/thumbnails", DocumentsController, :process_thumbnails)

    post("/documents/:document_id/tags/:tag", DocumentsController, :create_tag)
    delete("/documents/:document_id/tags/:tag", DocumentsController, :delete_tag)

    get("/documents", DocumentsController, :documents)
    post("/documents", DocumentsController, :upload_documents)

    get("/tags", TagController, :index)
    post("/tags", TagController, :update)

    get("/document-types", DocumentsController, :document_types)

    post("/settings/thumbnails", SettingsController, :process_all_thumbnails)
  end

  scope "/", Dms42Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/documents/thumbnail/:document_id", DocumentsController, :thumbnail)
    get("/documents/:document_id/images", DocumentsController, :document_image)
    get("/documents/:document_id/images/:image_id", DocumentsController, :document_image)

    get("/*path", PageController, :index)
  end
end

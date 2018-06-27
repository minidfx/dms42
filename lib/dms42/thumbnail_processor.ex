defmodule Dms42.ThumbnailProcessor do
  use GenServer

  require Logger

  alias Dms42.DocumentPath
  alias Dms42.DocumentsManager

  def start_link() do
    GenServer.start(
      __MODULE__,
      %{
        thumbnails_path: Application.get_env(:dms42, :thumbnails_path) |> Path.absname(),
        documents_path: Application.get_env(:dms42, :documents_path) |> Path.absname()
      },
      name: :thumbnail
    )
  end

  def handle_cast({:process, document, "application/pdf"}, %{:thumbnails_path => tp, :documents_path => dp} = state) do
    try do
      file_path = DocumentPath.document_path!(document)
      Logger.debug("Processing the thumbnail for the document #{file_path} ...")
      thumbnail_folder_path = String.replace_prefix(file_path, dp, tp)
      :ok = thumbnail_folder_path |> File.mkdir_p
      small_thumbnail_file_path = Path.join([thumbnail_folder_path, "small.png"])
      big_thumbnail_file_path = Path.join([thumbnail_folder_path, "big-%0d.png"])
      Logger.debug("Will save the thumbnail into #{thumbnail_folder_path}.")

      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(small_thumbnail_file_path)

      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(file_path)
      |> ExMagick.attr!(:adjoin, false)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(big_thumbnail_file_path)

      Dms42Web.Endpoint.broadcast!("documents:lobby", "newDocument", document |> DocumentsManager.transform_to_viewmodel)
    rescue
      x -> IO.inspect(x)
    end

    {:noreply, state}
  end

  def handle_cast({:process, document, _}, %{:thumbnails_path => tp, :documents_path => dp} = state) do
    try do
      file_path = DocumentPath.document_path!(document)
      Logger.debug("Processing the thumbnail for the document #{file_path} ...")
      thumbnail_folder_path = String.replace_prefix(file_path, dp, tp)
      :ok = thumbnail_folder_path |> File.mkdir_p
      small_thumbnail_file_path = Path.join([thumbnail_folder_path, "small.png"])
      Logger.debug("Will save the thumbnail into #{thumbnail_folder_path}.")

      ExMagick.init!()
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(small_thumbnail_file_path)

      Dms42Web.Endpoint.broadcast!("documents:lobby", "newDocument", document |> DocumentsManager.transform_to_viewmodel)
    rescue
      x -> IO.inspect(x)
    end

    {:noreply, state}
  end

  def init(args) do
    {:ok, args}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end
end

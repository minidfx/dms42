defmodule Dms42.ThumbnailProcessor do
  use GenServer

  require Logger

  alias Dms42.DocumentPath
  alias Dms42.Models.Document

  def start_link() do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: :thumbnail
    )
  end

  def init(args) do
    {:ok, args}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end

  def process(document) do
    %Document{:mime_type => mime_type} = document
    dp = Dms42.QueueState.get_documents_path()
    tp = Dms42.QueueState.get_thumbnails_path()

    case mime_type do
      "application/pdf" -> create_thumbnails_from_pdf(document, tp, dp)
      _ -> create_thumbnails_from_image(document, tp, dp)
    end
  end

  defp create_thumbnails_from_pdf(document, thumbnails_path, documents_path) do
    try do
      file_path = DocumentPath.document_path!(document)

      Logger.debug("Processing the thumbnail for the document #{file_path} ...")

      thumbnail_folder_path = String.replace_prefix(file_path, documents_path, thumbnails_path)
      :ok = thumbnail_folder_path |> File.mkdir_p()
      small_thumbnail_file_path = Path.join([thumbnail_folder_path, "small.png"])
      big_thumbnail_file_path = Path.join([thumbnail_folder_path, "big-%0d.png"])

      Logger.debug("Will save the thumbnail into #{thumbnail_folder_path}.")

      ExMagick.init!()
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump!(small_thumbnail_file_path)

      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(file_path)
      |> ExMagick.attr!(:adjoin, false)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump!(big_thumbnail_file_path)

      Logger.debug("Thumbnails saved for the document #{file_path}.")
      {:ok, document}
    rescue
      x -> {:error, x}
    end
  end

  defp create_thumbnails_from_image(document, thumbnails_path, documents_path) do
    try do
      file_path = DocumentPath.document_path!(document)
      Logger.debug("Processing the thumbnail for the document #{file_path} ...")

      thumbnail_folder_path = String.replace_prefix(file_path, documents_path, thumbnails_path)

      :ok = thumbnail_folder_path |> File.mkdir_p()
      small_thumbnail_file_path = Path.join([thumbnail_folder_path, "small.png"])

      Logger.debug("Will save the thumbnail into #{thumbnail_folder_path}.")

      ExMagick.init!()
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump!(small_thumbnail_file_path)

      Logger.debug("Thumbnails saved for the document #{file_path}.")
      {:ok, document}
    rescue
      x -> {:error, x}
    end
  end
end

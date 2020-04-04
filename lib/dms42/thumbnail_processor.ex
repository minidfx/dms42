defmodule Dms42.ThumbnailProcessor do
  use GenServer

  require Logger

  alias Dms42.DocumentPath

  def start_link() do
    GenServer.start_link(
      __MODULE__,
      %{
        thumbnails_path: Application.get_env(:dms42, :thumbnails_path) |> Path.absname(),
        documents_path: Application.get_env(:dms42, :documents_path) |> Path.absname()
      },
      name: :thumbnail
    )
  end

  def init(args) do
    {:ok, opq} = OPQ.init(name: :thumbnails_queue, workers: 1)
    {:ok, Map.put_new(args, :queue, opq)}
  end

  def terminate(reason, state) do
    IO.inspect(reason)

    case Map.get(state, :queue) do
      nil -> Logger.warn("Was not able to stop the queue.")
      x -> OPQ.stop(x)
    end
  end

  def handle_cast(
        {:process, document, "application/pdf"},
        %{:thumbnails_path => tp, :documents_path => dp, :queue => queue} = state
      ) do
    OPQ.enqueue(queue, fn -> create_thumbnails_from_pdf(document, tp, dp) end)
    {:noreply, state}
  end

  def handle_cast(
        {:process, document, _},
        %{:thumbnails_path => tp, :documents_path => dp, :queue => queue} = state
      ) do
    OPQ.enqueue(queue, fn -> create_thumbnails_from_image(document, tp, dp) end)
    {:noreply, state}
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
    rescue
      x -> IO.inspect(x)
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
    rescue
      x -> IO.inspect(x)
    end
  end
end

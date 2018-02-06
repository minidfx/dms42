defmodule Dms42.ThumbnailProcessor do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start(__MODULE__,
                    %{thumbnails_path: Application.get_env(:dms42, :thumbnails_path) |> Path.absname,
                    documents_path: Application.get_env(:dms42, :documents_path) |> Path.absname},
                    name: :thumbnail)
  end

  def handle_cast({:process, file_path, "application/pdf"}, %{:thumbnails_path => tp, :documents_path => dp} = state) do
    try do
      Logger.debug("Processing the thumbnail for the document #{file_path} ...")
      thumbnail_file_path = String.replace_prefix(file_path, dp, tp)
      small_thumbnail_file_path = thumbnail_file_path <> "_small"
      big_thumbnail_file_path = thumbnail_file_path <> "_big"
      Logger.debug("Will save the thumbnail to #{thumbnail_file_path}.")

      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(small_thumbnail_file_path)

      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(file_path)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(big_thumbnail_file_path)
    rescue
      x -> IO.inspect(x)
    end
    {:noreply, state}
  end

  def handle_cast({:process, file_path, _}, %{:thumbnails_path => tp, :documents_path => dp} = state) do
    try do
      Logger.debug("Processing the thumbnail for the document #{file_path} ...")
      thumbnail_file_path = String.replace_prefix(file_path, dp, tp)
      small_thumbnail_file_path = thumbnail_file_path <> "_small"
      Logger.debug("Will save the thumbnail to #{thumbnail_file_path}.")

      ExMagick.init!()
      |> ExMagick.image_load!(file_path)
      |> ExMagick.thumb!(155, 220)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(small_thumbnail_file_path)
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

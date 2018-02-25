defmodule Dms42.OcrProcessor do
  use GenServer
  alias Dms42.Models.DocumentOcr
  require Logger

  def start_link() do
    GenServer.start(__MODULE__, %{}, name: :ocr)
  end

  def init(args) do
    {:ok, args}
  end

  @callback handle_cast({:process, document_id :: binary, absolute_file_path :: String.t(), mime_type :: String.t()}, state :: map) :: {:ok, state :: map}
  def handle_cast({:process, document_id, absolute_file_path, "application/pdf"}, state) when is_binary(document_id) do
    Logger.debug("Starting the OCR on the PDF document  #{absolute_file_path} ...")
    {:ok, file_path} = Temp.path()
    try do
      ExMagick.init!()
      |> ExMagick.attr!(:density, "300")
      |> ExMagick.image_load!(absolute_file_path)
      |> ExMagick.attr!(:adjoin, true)
      |> ExMagick.attr!(:magick, "PNG")
      |> ExMagick.image_dump(file_path)

      IO.inspect(file_path)

      send_to_tesseract(document_id, file_path)
    rescue
      x ->
        Logger.error(x)
    end
    # :ok = File.rm(file_path)
    {:noreply, state}
  end

  @callback handle_cast({:process, document_id :: binary, absolute_file_path :: String.t(), mime_type :: String.t()}, state :: map) :: {:ok, state :: map}
  def handle_cast({:process, document_id, absolute_file_path, _mime_type}, state) do
    Logger.debug("Starting the OCR on the image document  #{absolute_file_path} ...")
    send_to_tesseract(document_id, absolute_file_path)
    {:noreply, state}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end

  @spec send_to_tesseract(document_id :: binary, file_path :: String.t()) :: no_return
  defp send_to_tesseract(document_id, file_path) do
    try do
      case Dms42.Tesseract.scan!(file_path) |> String.trim do
        "" ->
          Logger.warn("The result OCR was empty, insert or update was skipped.")

        x ->
          Logger.debug("Saving the OCR result ...")
          Dms42.Repo.insert_or_update!(DocumentOcr.changeset(%DocumentOcr{}, %{document_id: document_id, ocr: x}))
      end
    rescue
      _ -> Logger.warn("Error while processing the OCR for the file: #{file_path}")
    end
  end
end

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

  @callback handle_cast({:process, document_id :: String.t(), absolute_file_path :: String.t()}, state :: map) :: {:ok, state :: map}
  def handle_cast({:process, document_id, absolute_file_path}, state) do
    Logger.debug("Starting the OCR on the document: #{absolute_file_path}")
    extension = Path.extname(absolute_file_path)
    case extension do
      ".pdf" ->
        {:ok, handle, file_path} = Temp.open(absolute_file_path |> Path.basename |> Path.rootname)
        try do
          ExMagick.init!
              |> ExMagick.attr!(:density, "300")
              |> ExMagick.image_load!(absolute_file_path)
              |> ExMagick.attr!(:adjoin, false)
              |> ExMagick.image_dump(file_path)
          send_to_tesseract(document_id, file_path)
        rescue
          x ->
            Logger.error(x)
            File.close(handle)
            File.rm(file_path)
        end
      _ -> send_to_tesseract(document_id, absolute_file_path)
    end
    {:noreply, state}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end

  defp send_to_tesseract(document_id, file_path) do
    try do
      case Dms42.Tesseract.scan!(file_path) |> String.trim() do
        "" -> Logger.warn("The result OCR was empty, insert or update was skipped.")
        x ->
          Logger.debug("Saving the OCR result ...")
          Dms42.Repo.insert_or_update!(DocumentOcr.changeset(%DocumentOcr{}, %{document_id: document_id, ocr: x}))
      end
    rescue
      _ -> Logger.warn("Error while processing the OCR for the file: #{file_path}")
    end
  end
end

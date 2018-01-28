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

    try do
      case Dms42.Tesseract.scan!(absolute_file_path) |> String.trim() do
        "" -> Logger.warn("The result OCR was empty, insert or update was skipped.")
        x ->
          Logger.debug("Saving the OCR result ...")
          Dms42.Repo.insert_or_update!(DocumentOcr.changeset(%DocumentOcr{}, %{document_id: document_id, ocr: x}))
      end
    rescue
      _ -> Logger.warn("Error while processing the OCR for the file: #{absolute_file_path}")
    end

    {:noreply, state}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end
end

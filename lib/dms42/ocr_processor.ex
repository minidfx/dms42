defmodule Dms42.OcrProcessor do
  use GenServer

  alias Dms42.Models.DocumentOcr
  alias Dms42.DocumentsFinder

  require Logger

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: :ocr)
  end

  @doc false
  def init(args) do
    {:ok, opq} = OPQ.init(name: :ocr_queue, workers: 1)
    {:ok, Map.put_new(args, :queue, opq)}
  end

  @doc false
  def terminate(reason, state) do
    IO.inspect(reason)

    case Map.get(state, :queue) do
      nil -> Logger.warn("Was not able to stop the queue.")
      x -> OPQ.stop(x)
    end
  end

  @doc """
    Process the OCR on a document PDF save the result.
  """
  def handle_cast({:process, document_id, absolute_file_path, "application/pdf"}, state) do
    %{:queue => queue} = state
    OPQ.enqueue(queue, fn -> ocr_on_pdf(document_id, absolute_file_path) end)
    {:noreply, state}
  end

  @doc """
    Process the OCR on the image and save the result.
  """
  def handle_cast({:process, document_id, absolute_file_path, _mime_type}, state) do
    %{:queue => queue} = state
    OPQ.enqueue(queue, fn -> ocr_on_image(document_id, absolute_file_path) end)
    {:noreply, state}
  end

  defp send_to_tesseract(file_path, document_id) do
    try do
      case Dms42.External.tesseract!(file_path, lang: [:fra]) |> String.trim() do
        "" -> Logger.warn("The result OCR was empty, insert or update was skipped.")
        x -> save_ocr(x, document_id)
      end
    rescue
      x ->
        IO.inspect(x)
        Logger.warn("Error while processing the OCR for the file: #{file_path}")
    end
  end

  defp save_ocr(ocr, document_id) do
    Logger.debug("Saving the OCR result ...")

    Dms42.Repo.insert_or_update!(
      DocumentOcr.changeset(
        %DocumentOcr{},
        %{document_id: document_id, ocr: ocr, ocr_normalized: ocr |> DocumentsFinder.normalize()}
      )
    )

    Logger.debug("OCR saved for the document #{document_id}")
  end

  defp ocr_on_image(document_id, absolute_file_path) do
    Logger.debug("Starting the OCR on the image document  #{absolute_file_path} ...")
    send_to_tesseract(absolute_file_path, document_id)
  end

  defp ocr_on_pdf(document_id, absolute_file_path) do
    Logger.debug("Starting the OCR on the PDF document  #{absolute_file_path} ...")

    case Dms42.External.extract(absolute_file_path) do
      {:ok, ocr} ->
        Logger.debug("OCR extracted successfully from the PDF #{absolute_file_path}")
        save_ocr(ocr, document_id)

      {:error, error} ->
        try do
          Logger.warn(error)

          Temp.track!()
          file_path = Temp.path!()

          ExMagick.init!()
          |> ExMagick.attr!(:density, "300")
          |> ExMagick.image_load!(absolute_file_path)
          |> ExMagick.attr!(:adjoin, true)
          |> ExMagick.attr!(:magick, "PNG")
          |> ExMagick.image_dump(file_path)

          send_to_tesseract(file_path, document_id)
        rescue
          x ->
            Logger.error(x)
        end
    end
  end
end

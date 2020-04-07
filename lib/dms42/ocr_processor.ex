defmodule Dms42.OcrProcessor do
  use GenServer
  
  require Logger
  
  alias Dms42.Models.DocumentOcr
  alias Dms42.DocumentsFinder
  alias Dms42.Models.Document
  alias Dms42.DocumentPath

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: :ocr)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc false
  def terminate(reason, _) do
    IO.inspect(reason)
  end

  def process(document) do
    %Document{:mime_type => mime_type} = document
    case mime_type do
      "application/pdf" -> ocr_on_pdf(document)
      _ -> ocr_on_image(document)
    end
  end

  defp send_to_tesseract(document) do
    file_path = DocumentPath.document_path!(document)
    send_to_tesseract(document, file_path)
  end

  defp send_to_tesseract(document, path) do
    try do
      Logger.debug("Starting the OCR on the image document  #{path} ...")

      case Dms42.External.tesseract!(path, lang: [:fra]) |> String.trim() do
        "" ->
          Logger.warn("The result OCR was empty, insert or update was skipped.")
          {:ok, document}

        x ->
          save_ocr(x, document)
      end
    rescue
      x ->
        {:error, x}
    end
  end

  defp save_ocr(ocr, document) do
    %Document{:document_id => document_id} = document
    Logger.debug("Saving the OCR result ...")

    Dms42.Repo.insert_or_update!(
      DocumentOcr.changeset(
        %DocumentOcr{},
        %{document_id: document_id, ocr: ocr, ocr_normalized: ocr |> DocumentsFinder.normalize()}
      )
    )

    {:ok, uuid} = Ecto.UUID.load(document_id)
    Logger.debug("OCR saved for the document #{uuid}")
    {:ok, document}
  end

  defp ocr_on_image(document) do
    send_to_tesseract(document)
  end

  defp ocr_on_pdf(document) do
    file_path = DocumentPath.document_path!(document)

    case Dms42.External.extract(file_path) do
      {:ok, ocr} ->
        Logger.debug("OCR extracted successfully from the PDF #{file_path}")
        save_ocr(ocr, document)

      {:error, error} ->
        Logger.warn(error)

        Temp.track!()
        temp_file_path = Temp.path!()

        ExMagick.init!()
        |> ExMagick.attr!(:density, "300")
        |> ExMagick.image_load!(file_path)
        |> ExMagick.attr!(:adjoin, true)
        |> ExMagick.attr!(:magick, "PNG")
        |> ExMagick.image_dump(temp_file_path)

        send_to_tesseract(document, temp_file_path)
    end
  end
end

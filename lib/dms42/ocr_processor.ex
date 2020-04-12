defmodule Dms42.OcrProcessor do
  require Logger

  alias Dms42.Models.DocumentOcr
  alias Dms42.DocumentsFinder
  alias Dms42.Models.Document
  alias Dms42.DocumentPath

  @doc """
    Run and wait for the OCR process.
  """
  @spec process(Dms42.Models.Document.t()) :: {:ok, String.t()} | {:error, String.t()}
  def process(document) do
    %Document{:mime_type => mime_type} = document

    case mime_type do
      "application/pdf" -> ocr_on_pdf(document)
      _ -> ocr_on_image(document)
    end
  end

  ##### Private members

  @spec send_to_tesseract(Dms42.Models.Document.t()) ::
          {:ok, Dms42.Models.Document.t()} | {:error, any}
  defp send_to_tesseract(document) do
    file_path = DocumentPath.document_path!(document)
    send_to_tesseract(document, file_path)
  end

  @spec send_to_tesseract(Dms42.Models.Document.t(), String.t()) ::
          {:ok, Dms42.Models.Document.t()} | {:error, any}
  defp send_to_tesseract(document, path) do
    try do
      Logger.debug("Starting the OCR on the image document  #{path} ...")

      case Dms42.External.tesseract!(path, :fra) |> String.trim() do
        "" ->
          Logger.warn("The result OCR was empty, insert or update was skipped.")
          {:ok, document}

        x ->
          {:ok, save_ocr!(document, x)}
      end
    rescue
      x ->
        {:error, x}
    end
  end

  @spec save_ocr!(Dms42.Models.Document.t(), String.t()) :: Dms42.Models.Document.t()
  defp save_ocr!(document, ocr) do
    %Document{:document_id => document_id} = document

    document_ocr =
      case Dms42.Repo.get_by(DocumentOcr, document_id: document_id) do
        nil -> %DocumentOcr{}
        x -> x
      end

    Logger.debug("Saving the OCR result ...")

    Dms42.Repo.insert_or_update!(
      DocumentOcr.changeset(
        document_ocr,
        %{document_id: document_id, ocr: ocr, ocr_normalized: ocr |> DocumentsFinder.normalize()}
      )
    )

    {:ok, uuid} = Ecto.UUID.load(document_id)
    Logger.debug("OCR saved for the document #{uuid}")
    document
  end

  @spec ocr_on_image(Dms42.Models.Document.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp ocr_on_image(document) do
    send_to_tesseract(document)
  end

  @spec ocr_on_pdf(Dms42.Models.Document.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp ocr_on_pdf(document) do
    file_path = DocumentPath.document_path!(document)

    case Dms42.External.extract(file_path) do
      {:ok, ocr} ->
        Logger.debug("OCR extracted successfully from the PDF #{file_path}")
        {:ok, save_ocr!(document, ocr)}

      {:error, error} ->
        Logger.warn(error)

        try do
          try_to_ocr_on_each_page(document)
        rescue
          x ->
            Logger.error("An error occurred while processing the OCR on the document.")
            IO.inspect(x)
            {:ok, document}
        end
    end
  end

  @spec try_to_ocr_on_each_page(Dms42.Models.Document.t()) :: Dms42.Models.Document.t()
  defp try_to_ocr_on_each_page(document) do
    file_path = DocumentPath.document_path!(document)
    temp_folder_path = Temp.mkdir!()
    temp_files_pattern = Dms42.DocumentPath.big_thumbnail_paths_pattern!(temp_folder_path)

    Dms42.External.transform_document(file_path, temp_files_pattern,
      scale: 800,
      density: 200,
      quality: 100
    )

    ocr =
      temp_folder_path
      |> Dms42.DocumentPath.list_big_thumbnails()
      |> Enum.map(fn x -> Dms42.External.tesseract!(x, :fra) end)
      |> Enum.join()

    save_ocr!(document, ocr)

    cleanup(temp_folder_path)

    {:ok, document}
  end

  @spec cleanup(String.t()) :: :ok
  defp cleanup(folder) do
    File.rm_rf!(folder)
    :ok
  end
end

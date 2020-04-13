defmodule Dms42.ThumbnailProcessor do
  use Pipe

  require Logger

  alias Dms42.DocumentPath
  alias Dms42.Models.Document

  @spec process(Dms42.Models.Document) :: {:ok, Dms42.Models.Document} | {:error, any()}
  def process(document) do
    %Document{:mime_type => mime_type} = document

    case mime_type do
      "application/pdf" -> create_thumbnails_from_pdf(document)
      _ -> create_thumbnails_from_image(document)
    end
  end

  @spec create_thumbnails_from_pdf(Dms42.Models.Document) ::
          {:ok, Dms42.Models.Document} | {:error, any()}
  defp create_thumbnails_from_pdf(document) do
    try do
      file_path = DocumentPath.document_path!(document)
      small_thumbnail_temp_path = Temp.path!()
      big_thumbnails_temp_path = Temp.mkdir!()
      big_thumbnails_temp_path_pattern = Dms42.DocumentPath.big_thumbnail_paths_pattern!(big_thumbnails_temp_path)

      Logger.debug("Processing the thumbnail from a PDF for the document #{file_path} ...")

      Dms42.DocumentPath.ensure_thumbnails_folder_exists!(document)
      small_thumbnail_file_path = Dms42.DocumentPath.small_thumbnail_path!(document)
      big_thumbnail_file_path_pattern = Dms42.DocumentPath.big_thumbnail_paths_pattern!(document)
      thumbnail_folder_path = Dms42.DocumentPath.thumbnail_folder_path!(document)

      Logger.debug(
        "Pre-process validation: small thumbnail exists(#{File.exists?(small_thumbnail_file_path)})"
      )

      Logger.info("Saving the thumbnail into #{thumbnail_folder_path} ...")

      Dms42.External.transform_document(file_path, small_thumbnail_temp_path,
        max_width: 155,
        max_height: 220,
        only_first_page: true,
        is_thumbnail: true
      )

      Dms42.External.transform_document(file_path, big_thumbnails_temp_path_pattern,
        scale: 800,
        density: 200
      )

      Logger.debug("Moving the thumbnails generated: #{big_thumbnails_temp_path} -> #{thumbnail_folder_path}")

      File.cp!(small_thumbnail_temp_path, small_thumbnail_file_path, fn _, _ -> true end)
      File.cp_r!(big_thumbnails_temp_path, thumbnail_folder_path, fn _, _ -> true end)

      Logger.debug("Thumbnails saved for the document #{file_path}.")
      {:ok, document}
    rescue
      x -> {:error, x}
    end
  end

  @spec create_thumbnails_from_image(Dms42.Models.Document) ::
          {:ok, Dms42.Models.Document} | {:error, any()}
  defp create_thumbnails_from_image(document) do
    try do
      file_path = DocumentPath.document_path!(document)
      small_thumbnail_temp_path = Temp.path!()
      big_thumbnail_temp_path = Temp.path!()

      Logger.debug("Processing the thumbnail from an image for the document #{file_path} ...")

      Dms42.DocumentPath.ensure_thumbnails_folder_exists!(document)
      small_thumbnail_file_path = Dms42.DocumentPath.small_thumbnail_path!(document)
      big_thumbnail_file_path = Dms42.DocumentPath.big_first_thumbnail_path!(document)

      Logger.debug(
        "Pre-process validation: small thumbnail exists(#{File.exists?(small_thumbnail_file_path)})"
      )

      Logger.info("Saving the thumbnail to #{small_thumbnail_file_path}.")

      Dms42.External.transform_document(file_path, small_thumbnail_temp_path,
        max_width: 155,
        max_height: 220,
        is_thumbnail: true
      )

      Dms42.External.transform_document(file_path, big_thumbnail_temp_path)

      Logger.debug("Moving the thumbnails generated ...")

      File.cp!(small_thumbnail_temp_path, small_thumbnail_file_path, fn _, _ -> true end)
      File.cp!(big_thumbnail_temp_path, big_thumbnail_file_path, fn _, _ -> true end)

      Logger.debug("Thumbnails saved for the document #{file_path}.")
      {:ok, document}
    rescue
      x -> {:error, x}
    end
  end
end

defmodule Dms42.ThumbnailProcessor do
  use GenServer
  use Pipe

  require Logger

  alias Dms42.DocumentPath
  alias Dms42.Models.Document

  @doc false
  def start_link() do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: :thumbnail
    )
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  @doc false
  def terminate(reason, _) do
    IO.inspect(reason)
  end

  @doc false
  def handle_cast({:process, document}, state) do
    process(document)
    {:noreply, state}
  end

  @spec process(Dms42.Models.Document) :: :ok
  def cast_process(document) do
    GenServer.cast(:thumbnail, {:process, document})
  end

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

      Logger.debug("Processing the thumbnail from a PDF for the document #{file_path} ...")

      Dms42.DocumentPath.ensure_thumbnails_folder_exists!(document)
      small_thumbnail_file_path = Dms42.DocumentPath.small_thumbnail_path!(document)
      big_thumbnail_file_path = Dms42.DocumentPath.big_thumbnail_paths_pattern!(document)
      thumbnail_folder_path = Dms42.DocumentPath.thumbnail_folder_path!(document)

      Logger.debug(
        "Pre-process validation: small thumbnail exists(#{File.exists?(small_thumbnail_file_path)})"
      )

      Logger.info("Will save the thumbnail into #{thumbnail_folder_path}.")

      Dms42.External.transform_document(file_path, small_thumbnail_file_path,
        max_width: 155,
        max_height: 220,
        only_first_page: true,
        is_thumbnail: true
      )

      Dms42.External.transform_document(file_path, big_thumbnail_file_path,
        scale: 800,
        density: 200,
        quality: 100
      )

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
      Logger.debug("Processing the thumbnail from an image for the document #{file_path} ...")

      Dms42.DocumentPath.ensure_thumbnails_folder_exists!(document)
      small_thumbnail_file_path = Dms42.DocumentPath.small_thumbnail_path!(document)
      big_thumbnail_file_path = Dms42.DocumentPath.big_thumbnail_paths_pattern!(document)

      Logger.debug(
        "Pre-process validation: small thumbnail exists(#{File.exists?(small_thumbnail_file_path)})"
      )

      Logger.info("Will save the thumbnail to #{small_thumbnail_file_path}.")

      Dms42.External.transform_document(file_path, small_thumbnail_file_path,
        max_width: 155,
        max_height: 220,
        is_thumbnail: true
      )

      Dms42.External.transform_document(file_path, big_thumbnail_file_path)

      Logger.debug("Thumbnails saved for the document #{file_path}.")
      {:ok, document}
    rescue
      x -> {:error, x}
    end
  end
end

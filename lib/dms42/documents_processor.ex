defmodule Dms42.DocumentsProcessor do
  use Pipe

  require Logger

  alias Dms42.Models.Document
  alias Dms42.Models.NewDocumentProcessingContext
  alias Dms42.Models.DocumentType
  alias Dms42.DocumentPath
  alias Dms42.TagManager
  alias Dms42.DocumentsFinder
  alias Dms42.DocumentsManager

  def process(
        original_file_name,
        mime_type,
        original_file_datetime,
        document_type,
        tags,
        bytes
      ) do
    result =
      Pipe.pipe_matching(
        {:ok, _},
        {:ok,
         %NewDocumentProcessingContext{
           document: %Document{
             inserted_at: DateTime.utc_now(),
             original_file_name: original_file_name,
             original_file_name_normalized: original_file_name |> DocumentsFinder.normalize(),
             document_id: Ecto.UUID.bingenerate(),
             original_file_datetime: original_file_datetime,
             mime_type: mime_type
           },
           type: document_type,
           transaction: Ecto.Multi.new()
         }}
        |> valid_file_type
        |> valid_file_path
        |> valid_document_type
        |> is_document_exists(bytes)
        |> save_file(bytes)
        |> clean_image
        |> insert_to_database
        |> insert_tags(tags)
        |> commit
        |> thumbnails
        |> ocr
      )

    case result do
      {:ok, _} -> Logger.info("Document processed successfully.")
      {:error, reason} -> Logger.error(reason)
    end
  end

  defp ocr({:ok, document}) do
    {:ok, _} = Dms42.OcrProcessor.process(document)
    {:ok, document}
  end

  defp thumbnails({:ok, document}) do
    Dms42.ThumbnailProcessor.process(document)
  end

  defp commit(
         {:ok, %NewDocumentProcessingContext{:transaction => transaction, :document => document}}
       ) do
    case Dms42.Repo.transaction(transaction) do
      {:error, table, _, _} ->
        DocumentPath.document_path!(document) |> File.rm!()
        {:error, "Cannot save the transaction because the table #{table} thrown an error."}

      {:error, _} ->
        {:error, "Cannot save the transaction."}

      {:ok, _} ->
        %Document{:document_id => document_id, :mime_type => mime_type} = document
        absolute_documents_path = DocumentPath.document_path!(document)
        {:ok, document}
    end
  end

  defp valid_document_type(
         {:ok, %NewDocumentProcessingContext{:type => document_type_string_id} = context}
       ) do
    {:ok, uuid} = Ecto.UUID.dump(document_type_string_id)

    case Dms42.Repo.get_by(DocumentType, type_id: uuid) do
      nil ->
        {:error, "The given document type is not found: #{document_type_string_id}"}

      %{type_id: type_id} ->
        %{:document => document} = context
        {:ok, %{context | document: %{document | document_type_id: type_id}}}
    end
  end

  defp insert_tags(result, []), do: result

  defp insert_tags(
         {:ok,
          %NewDocumentProcessingContext{
            :transaction => transaction,
            :document => %Document{:document_id => document_id}
          } = context},
         tags
       ) do
    [tag | tail] = tags

    insert_tags(
      {:ok,
       %NewDocumentProcessingContext{
         context
         | :transaction => transaction |> TagManager.add_or_update(document_id, tag)
       }},
      tail
    )
  end

  defp insert_to_database(
         {:ok,
          %NewDocumentProcessingContext{:transaction => transaction, :document => document} =
            context}
       ) do
    {:ok,
     %NewDocumentProcessingContext{
       context
       | transaction:
           transaction
           |> Ecto.Multi.insert(
             :document,
             Document.changeset(%Document{}, document |> Map.from_struct())
           )
     }}
  end

  defp is_document_exists(
         {:ok,
          %NewDocumentProcessingContext{
            :document => %{:original_file_name => file_name} = document
          } = context},
         bytes
       ) do
    case DocumentsManager.is_document_exists(bytes) do
      {false, hash} ->
        {:ok, %NewDocumentProcessingContext{context | document: %Document{document | hash: hash}}}

      {true, _} ->
        Logger.info("The document #{file_name} seems already exists.")
        {:error, "This document seems conflict with another the document."}
    end
  end

  defp valid_file_path({:ok, %NewDocumentProcessingContext{:document => document} = context}) do
    absolute_thumbnails_folder_path =
      DocumentPath.small_thumbnail_path!(document) |> Path.dirname()

    absolute_documents_folder_path = DocumentPath.document_path!(document) |> Path.dirname()
    documents_folder_result = absolute_documents_folder_path |> File.mkdir_p()
    thumbnails_folder_result = absolute_thumbnails_folder_path |> File.mkdir_p()

    case {documents_folder_result, thumbnails_folder_result} do
      {:ok, :ok} ->
        {:ok, context}

      {_, {:error, reason}} ->
        {:error,
         "Cannot create the folder structure #{absolute_thumbnails_folder_path}: " <>
           Atom.to_string(reason)}

      {{:error, reason}, _} ->
        {:error,
         "Cannot create the folder structure #{absolute_documents_folder_path}: " <>
           Atom.to_string(reason)}
    end
  end

  defp save_file(
         {:ok,
          %NewDocumentProcessingContext{
            :document => %Document{:original_file_name => file_name} = document
          } = context},
         bytes
       ) do
    file_path = DocumentPath.document_path!(document)

    if File.exists?(file_path) do
      raise "File already exists, exception currently not supported."
    end

    document_write_result = File.write(file_path, bytes, [:write])

    case document_write_result do
      :ok ->
        Logger.debug("File #{file_name} wrote to #{file_path}.")
        {:ok, context}

      {:error, reason} ->
        {:error, "Cannot write the file #{file_path}: " <> Atom.to_string(reason)}
    end
  end

  defp clean_image(
         {:ok,
          %NewDocumentProcessingContext{
            :document => %{:mime_type => mime_type} = document
          } = context}
       ) do
    file_path = DocumentPath.document_path!(document)

    case Dms42.External.clean_image(file_path, mime_type) do
      {:ok, _} -> {:ok, context}
      {:none, _} -> {:ok, context}
      x -> x
    end
  end

  defp valid_file_type(
         {:ok,
          %{:document => %Document{:mime_type => mime_type, :original_file_name => file_name}} =
            context}
       ) do
    allowed_types = ["application/pdf", "image/jpeg", "image/png"]

    case Enum.any?(allowed_types, fn x -> x == mime_type end) do
      false -> {:error, " The file #{file_name} is not supported: #{mime_type}"}
      true -> {:ok, context}
    end
  end
end

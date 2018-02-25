defmodule Dms42.DocumentsManager do
  require Logger

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.Models.NewDocumentProcessingContext
  alias Dms42.Models.DocumentType
  alias Dms42.DocumentPath

  def start_link() do
    GenServer.start(__MODULE__, %{}, name: :documents_manager)
  end

  def init(args) do
    {:ok, args}
  end

  def terminate(reason, _) do
    IO.inspect(reason)
  end

  def handle_cast({:process, file_name, mime_type, original_file_datetime, document_type, tags, bytes}, state) do
    result = %NewDocumentProcessingContext{
      document: %Document{
        inserted_at: DateTime.utc_now(),
        original_file_name: file_name,
        document_id: Ecto.UUID.bingenerate(),
        original_file_datetime: original_file_datetime,
        mime_type: mime_type,
        hash: :crypto.hash(:sha256, bytes) |> Base.encode16()
      },
      type: document_type,
      transaction: Ecto.Multi.new()
    }
    |> valid_file_type
    |> valid_file_path
    |> valid_document_type
    |> is_document_exist
    |> save_file(bytes)
    |> insert_to_database
    |> insert_tags(tags)
    |> commit

    case result do
      {:ok, document} ->
          file_path = DocumentPath.document_path!(document)
          Logger.info("Document #{file_path} successfully added.")
      {:error, reason} -> Logger.error(reason)
    end

    {:noreply, state}
  end

  @spec commit({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp commit({:error, _reason} = error), do: error

  defp commit({:ok, %NewDocumentProcessingContext{:transaction => transaction, :document => document}}) do
    case Dms42.Repo.transaction(transaction) do
      {:error, table, _, _} ->
        DocumentPath.document_path!(document) |> File.rm!
        {:error, "Cannot save the transaction because the table #{table} thrown an error."}

      {:error, _} ->
        {:error, "Cannot save the transaction."}

      {:ok, _} ->
        %Document{:document_id => document_id, :mime_type =>  mime_type} = document
        absolute_documents_path = DocumentPath.document_path!(document)
        GenServer.cast(:ocr, {:process, document_id, absolute_documents_path, mime_type})
        GenServer.cast(:thumbnail, {:process, absolute_documents_path, mime_type})
        {:ok, document}
    end
  end

  @spec valid_document_type({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) :: {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  def valid_document_type({:ok, %NewDocumentProcessingContext{:type => document_type_string_id} = context}) do
    {:ok, uuid} = Ecto.UUID.dump(document_type_string_id)
    case Dms42.Repo.get_by(DocumentType, [type_id: uuid]) do
      nil -> {:error, "The given document type is not found: #{document_type_string_id}"}
      %{type_id: type_id} ->
        %{:document => document} = context
        {:ok, %{context | document: %{document | document_type_id: type_id}}}
    end
  end
  def valid_document_type({:error, _} = error), do: error

  @spec insert_tags({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}, list(String.t())) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp insert_tags({:error, _reason} = error, _), do: error

  defp insert_tags(result, []), do: result

  defp insert_tags({:ok, %NewDocumentProcessingContext{:transaction => transaction, :document => %Document{:document_id => document_id}} = context}, [
         head | tail
       ]) do
    case Dms42.Repo.get_by(Tag, name: head) do
      nil ->
        tag_id = Ecto.UUID.bingenerate()

        insert_tags(
          {:ok,
           %NewDocumentProcessingContext{
             context
             | :transaction =>
                 transaction
                 |> Ecto.Multi.insert("Tag#{head}", Tag.changeset(%Tag{}, %{name: head |> String.trim |> String.downcase, tag_id: tag_id}))
                 |> Ecto.Multi.insert(
                   "DocumentTag#{head}",
                   DocumentTag.changeset(%DocumentTag{}, %{document_id: document_id, tag_id: tag_id})
                 )
           }},
          tail
        )

      %Tag{:tag_id => tag_id} ->
        insert_tags(
          {:ok,
           %NewDocumentProcessingContext{
             context
             | :transaction =>
                 transaction
                 |> Ecto.Multi.insert(
                   "DocumentTag#{head}",
                   DocumentTag.changeset(%DocumentTag{}, %{document_id: document_id, tag_id: tag_id})
                 )
           }},
          tail
        )
    end
  end

  @spec insert_to_database({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp insert_to_database({:error, _reason} = error), do: error

  defp insert_to_database({:ok, %NewDocumentProcessingContext{:transaction => transaction, :document => document} = context}) do
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

  @spec update(document :: Document) :: :ok | {:error, reason :: String.t()}
  def update(%Document{}) do
    {:error, "Not implemented"}
  end

  @spec is_document_exist({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, String.t()}
  defp is_document_exist({:error, _} = error), do: error

  defp is_document_exist({:ok, %NewDocumentProcessingContext{:document => %{:hash => hash}} = context}) do
    case Dms42.Repo.get_by(Document, hash: hash) do
      nil ->
        {:ok, context}

      %Document{:document_id => document_id, :original_file_name => file_name} ->
        {:ok, uuid} = Ecto.UUID.load(document_id)
        Logger.info("The document #{file_name} conflict with the document #{uuid}")
        {:error, "This document seems conflict with another the document."}
    end
  end

  @spec valid_file_path({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp valid_file_path({:error, _reason} = error), do: error

  defp valid_file_path({:ok, %NewDocumentProcessingContext{:document => document} = context}) do
    absolute_thumbnails_folder_path = DocumentPath.small_thumbnail_path!(document) |> Path.dirname
    absolute_documents_folder_path = DocumentPath.document_path!(document) |> Path.dirname
    documents_folder_result = absolute_documents_folder_path |> File.mkdir_p
    thumbnails_folder_result = absolute_thumbnails_folder_path |> File.mkdir_p

    case {documents_folder_result, thumbnails_folder_result} do
      {:ok, :ok} ->
        {:ok, context}

      {_, {:error, reason}} ->
        {:error, "Cannot create the folder structure #{absolute_thumbnails_folder_path}: " <> Atom.to_string(reason)}

      {{:error, reason}, _} ->
        {:error, "Cannot create the folder structure #{absolute_documents_folder_path}: " <> Atom.to_string(reason)}
    end
  end

  @spec save_file({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}, binary) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp save_file({:error, _reason} = error, _bytes), do: error

  defp save_file(
         {:ok, %NewDocumentProcessingContext{:document => %Document{:original_file_name => file_name} = document} = context},
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

  @spec valid_file_type(NewDocumentProcessingContext) :: {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp valid_file_type(%{:document => %Document{:mime_type => mime_type, :original_file_name => file_name}} = context) do
    allowed_types = ["application/pdf", "image/jpeg", "image/png"]

    case Enum.any?(allowed_types, fn x -> x == mime_type end) do
      false -> {:error, " The file #{file_name} is not supported: #{mime_type}"}
      true -> {:ok, context}
    end
  end
end

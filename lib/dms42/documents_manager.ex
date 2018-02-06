defmodule Dms42.DocumentsManager do
  require Logger
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.Models.NewDocumentProcessingContext

  @spec add(
          file_name :: String.t(),
          mime_type :: String.t(),
          original_file_datetime :: DateTime.t(),
          document_type :: Ecto.UUID,
          tags :: list(String.t()),
          bytes :: binary
        ) :: {:ok, Document} | {:error, reason :: String.t()}
  def add(file_name, mime_type, original_file_datetime, document_type, tags, bytes) do
    IO.inspect tags
    %NewDocumentProcessingContext{
      document: %Document{
        original_file_name: file_name,
        document_id: Ecto.UUID.bingenerate(),
        document_type_id: document_type,
        original_file_datetime: original_file_datetime,
        mime_type: mime_type,
        hash: :crypto.hash(:sha256, bytes) |> Base.encode16()
      },
      transaction: Ecto.Multi.new()
    }
    |> valid_file_type
    |> valid_file_path
    |> is_document_exist
    |> save_file(bytes)
    |> insert_to_database
    |> insert_tags(tags)
    |> commit
  end

  @spec remove(document_id :: integer) :: :ok | {:error, reason :: String.t()}
  def remove(document_id) do
    {:error, "Not implemented"}
  end

  @spec delete(document_id :: integer) :: :ok | {:error, reason :: String.t()}
  def delete(document_id) do
    {:error, "Not implemented"}
  end

  @spec commit({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp commit({:error, _reason} = error), do: error

  defp commit({:ok, %NewDocumentProcessingContext{:transaction => transaction, :document => document}}) do
    case Dms42.Repo.transaction(transaction) do
      {:error, table, changeset, _} ->
        %Document{:file_path => file_path} = document
        base_documents_path = Application.get_env(:dms42, :documents_path) |> Path.absname()
        absolute_documents_path = Path.join([base_documents_path, file_path])

        File.rm!(absolute_documents_path)

        IO.inspect(changeset)
        {:error, "Cannot save the transaction because the table #{table} thrown an error."}

      {:error, changeset} ->
        IO.inspect(changeset)
        {:error, "Cannot save the transaction."}

      {:ok, _} ->
        %Document{:document_id => document_id, :file_path => file_path} = document
        base_documents_path = Application.get_env(:dms42, :documents_path) |> Path.absname()
        absolute_documents_path = Path.join([base_documents_path, file_path])
        GenServer.cast(:ocr, {:process, document_id, absolute_documents_path})
        GenServer.cast(:thumbnail, {:process, absolute_documents_path})
        {:ok, document}
    end
  end

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
                 |> Ecto.Multi.insert("Tag#{head}", Tag.changeset(%Tag{}, %{name: head |> String.trim |> String.Casing.downcase, tag_id: tag_id}))
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
        Logger.info("The document #{file_name} conflict with the document #{document_id}")
        {:error, "This document seems conflict with another the document."}
    end
  end

  @spec valid_file_path({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp valid_file_path({:error, _reason} = error), do: error

  defp valid_file_path({:ok, %NewDocumentProcessingContext{:document => %Document{:document_id => document_id} = document} = context}) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    base_documents_path = Application.get_env(:dms42, :documents_path) |> Path.absname()
    base_thumbnails_path = Application.get_env(:dms42, :thumbnails_path) |> Path.absname()

    if base_documents_path == nil do
      raise("Invalid application documents path, please verify your configuration.")
    end

    relative_path = Path.join([Integer.to_string(year), Integer.to_string(month), Integer.to_string(day)])

    absolute_documents_directory_path = Path.join([base_documents_path, relative_path])
    absolute_thumbnails_directory_path = Path.join([base_thumbnails_path, relative_path])

    documents_directories_result = File.mkdir_p(absolute_documents_directory_path)
    documents_thumbnails_result = File.mkdir_p(absolute_thumbnails_directory_path)

    case {documents_directories_result, documents_thumbnails_result} do
      {:ok, :ok} ->
        {:ok, uuid} = document_id |> Ecto.UUID.load()
        {:ok, %NewDocumentProcessingContext{context | document: %Document{document | file_path: Path.join([relative_path, uuid])}}}

      {_, {:error, reason}} ->
        {:error, "Cannot create the folder structure #{absolute_thumbnails_directory_path}: " <> Atom.to_string(reason)}

      {{:error, reason}, _} ->
        {:error, "Cannot create the folder structure #{absolute_documents_directory_path}: " <> Atom.to_string(reason)}
    end
  end

  @spec save_file({:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}, binary) ::
          {:ok, NewDocumentProcessingContext} | {:error, reason :: String.t()}
  defp save_file({:error, _reason} = error, _bytes), do: error

  defp save_file(
         {:ok, %NewDocumentProcessingContext{:document => %Document{:original_file_name => file_name, :file_path => file_path}} = context},
         bytes
       ) do
    if File.exists?(file_path) do
      raise "File already exists, exception currently not supported."
    end

    absolute_documents_path = Path.join([Application.get_env(:dms42, :documents_path) |> Path.absname(), file_path])
    document_write_result = File.write(absolute_documents_path, bytes, [:write])

    case document_write_result do
      :ok ->
        Logger.debug("File #{file_name} wrote to #{absolute_documents_path}.")
        {:ok, context}

      {:error, reason} ->
        {:error, "Cannot write the file #{absolute_documents_path}: " <> Atom.to_string(reason)}
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

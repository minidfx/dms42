defmodule Dms42.DocumentManager do
  require Logger
  alias Dms42.Models.Document
  import Ecto

  @spec add(mime_type :: String.t, file_name :: String.t, bytes :: binary) :: {:ok, Document} | {:error, reason :: String.t}
  def add(mime_type, file_name, bytes) do
    Logger.debug("File received: #{file_name}")
    %Document{original_file_name: file_name,
              document_id: Ecto.UUID.bingenerate(),
              mime_type: mime_type} |> valid_file_type
                                    |> valid_file_path
                                    |> save_file(bytes)
                                    |> insert_to_database
  end

  @spec remove(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def remove(document_id) do
    {:error, "Not implemented"}
  end

  @spec delete(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def delete(document_id) do
    {:error, "Not implemented"}
  end

  @spec insert_to_database({:ok, Document} | {:error, reason :: String.t}) :: {:ok, Document} | {:error, reason :: String.t}
  defp insert_to_database({:error, _reason} = error), do: error
  defp insert_to_database({:ok, document}) do
    case Dms42.Repo.insert(Document.changeset(%Document{}, document |> Map.from_struct)) do
      {:error, _changeset} -> "Cannot save the document to the database."
      {:ok, document_inserted} -> {:ok, document_inserted}
    end
  end

  @spec update(document :: Document) :: :ok | {:error, reason :: String.t}
  def update(%Document{}) do
    {:error, "Not implemented"}
  end

  @spec valid_file_path({:ok, Document} | {:error, reason :: String.t}) :: {:ok, Document} | {:error, reason :: String.t}
  defp valid_file_path({:error, _reason} = error), do: error
  defp valid_file_path({:ok, %Document{:document_id => document_id} = document}) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    base_documents_path = Application.get_env(:dms42, :documents_path) |> Path.absname
    if base_documents_path == nil do
      raise("Invalid application documents path, please verify your configuration.")
    end
    relative_path = Path.join([Integer.to_string(year), Integer.to_string(month), Integer.to_string(day)])
    absolute_directory_path = Path.join([base_documents_path, relative_path])
    case File.mkdir_p(absolute_directory_path) do
      {:error, reason} ->  {:error, "Cannot create the folder structure for #{absolute_directory_path}: " <> Atom.to_string(reason)}
      :ok ->
        {:ok, uuid} = document_id |> Ecto.UUID.load
        {:ok, %Document{document | file_path: Path.join([relative_path, uuid])}}
    end
  end

  @spec save_file({:ok, Document} | {:error, reason :: String.t}, binary) :: {:ok, Document} | {:error, reason :: String.t}
  defp save_file({:error, _reason} = error, _bytes), do: error
  defp save_file({:ok, %Document{:original_file_name => file_name, :file_path => file_path} = document}, bytes) do
    if File.exists?(file_path) do
      raise "File already exists, exception currently not supported."
    end
    absolute_path = Path.join([Application.get_env(:dms42, :documents_path) |> Path.absname, file_path])
    case File.write(absolute_path, bytes, [:write]) do
      {:error, reason} -> {:error, "Cannot write the file #{absolute_path}: " <> Atom.to_string(reason)}
      :ok ->
          Logger.debug("File #{file_name} wrote to #{absolute_path}.")
          {:ok, document}
    end
  end

  @spec valid_file_type(Document) :: {:ok, Document} | {:error, reason :: String.t}
  defp valid_file_type(%Document{:mime_type => mime_type, :original_file_name => file_name} = document) do
    allowed_types = ["application/pdf", "image/gif", "image/jpeg", "image/png"]
    case Enum.any?(allowed_types, fn x -> x == mime_type end) do
      false -> {:error, " The file #{file_name} is not supported: #{mime_type}"}
      true -> {:ok, document}
    end
  end
end

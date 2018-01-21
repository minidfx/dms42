defmodule Dms42.DocumentManager do
  require Logger
  alias Dms42.Models.Document
  import Ecto

  @spec add(file_name :: String.t, bytes :: binary) :: {:ok, Document} | {:error, reason :: String.t}
  def add(file_name, bytes) do
    Logger.debug("File received: #{file_name}")
    new_document = %Document{document_id: Ecto.UUID.generate()}
  end

  @spec remove(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def remove(document_id) do
    {:error, "Not implemented"}
  end

  @spec delete(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def delete(document_id) do
    {:error, "Not implemented"}
  end

  @spec update(document :: Document) :: :ok | {:error, reason :: String.t}
  def update(%Document{}) do
    {:error, "Not implemented"}
  end
end

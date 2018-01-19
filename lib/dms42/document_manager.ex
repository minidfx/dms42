defmodule Dms42.DocumentManager do

  alias Dms42.Models.Document

  @spec add(file_name :: String.t, bytes :: bitstring) :: :ok | {:error, reason :: String.t}
  def add(file_name, bytes) do

  end

  @spec remove(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def remove(document_id) do

  end

  @spec delete(document_id :: integer) :: :ok | {:error, reason :: String.t}
  def delete(document_id) do

  end

  @spec update(document :: Document) :: :ok | {:error, reason :: String.t}
  def update(%Document{}) do

  end

end

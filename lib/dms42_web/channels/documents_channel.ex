defmodule Dms42Web.DocumentsChannel do
  use Dms42Web, :channel
  require Logger
  alias Dms42.Models.DocumentType

  def join("documents:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # # Channels can be used in a request/response fashion
  # # by sending replies to requests from the client
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end
  #
  # # It is also common to receive messages from the client and
  # # broadcast to everyone in the current topic (documents:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  def handle_info(:after_join, socket) do
    document_types =
      Dms42.Repo.all(DocumentType)
      |> Enum.map(fn %{:name => name, :type_id => type_id} -> %{"name" => name, "id" => type_id} end)

    Phoenix.Channel.push(socket, "documentTypes", %{
      "document-types" => document_types
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

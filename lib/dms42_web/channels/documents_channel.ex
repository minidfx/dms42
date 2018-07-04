defmodule Dms42Web.DocumentsChannel do
  use Dms42Web, :channel

  require Logger

  alias Dms42.Models.DocumentType
  alias Dms42.DocumentsManager
  alias Dms42.DocumentsFinder

  def join("documents:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    document_types = DocumentType |> Dms42.Repo.all
                                  |> Enum.map(fn %{:name => name, :type_id => type_id} ->
                                                {:ok, uuid} = Ecto.UUID.load(type_id)
                                                %{"name" => name, "id" => uuid}
                                              end)
    documents = DocumentsManager.documents(0, 50)

    Phoenix.Channel.push(socket, "initialLoad", %{"document-types": document_types, "documents": documents})
    {:noreply, socket}
  end

  def handle_in("document:comments", %{"comments" => comments, "document_id" => document_id}, socket) do
    document = DocumentsManager.edit_comments!(document_id, comments)
    Phoenix.Channel.push(socket, "updateDocument", document |> DocumentsManager.transform_to_viewmodel)
    {:reply, :ok, socket}
  end

  def handle_in("documents:search", %{"query" => query}, socket) do
    Phoenix.Channel.push(socket, "searchResult", %{"result": DocumentsFinder.find(query) |> DocumentsManager.transform_to_viewmodels})
    {:reply, :ok, socket}
  end

  def handle_in("document:get", %{"document_id" => document_id}, socket) do
    {:ok, uuid} = document_id |> Ecto.UUID.dump
    Phoenix.Channel.push(socket,
                         "newDocument",
                         %{"result": DocumentsManager.get(uuid) |> DocumentsManager.transform_to_viewmodel})
    {:reply, :ok, socket}
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

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

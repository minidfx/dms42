defmodule Dms42Web.DocumentsChannel do
  use Dms42Web, :channel

  require Logger

  alias Dms42.Models.DocumentType
  alias Dms42.DocumentsManager
  alias Dms42.DocumentsFinder
  alias Dms42.DocumentPath
  alias Dms42.TagManager

  def join("documents:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # def handle_info(:after_join, socket) do
  #   document_types = DocumentType |> Dms42.Repo.all
  #                                 |> Enum.map(fn %{:name => name, :type_id => type_id} ->
  #                                               {:ok, uuid} = Ecto.UUID.load(type_id)
  #                                               %{"name" => name, "id" => uuid}
  #                                             end)
  #   documents = DocumentsManager.documents(0, 20)
  #   documents_ocr = DocumentsManager.ocr(documents |> Enum.map(fn %{"document_id" => x} ->
  #                                                               {:ok, uuid} = Ecto.UUID.dump(x)
  #                                                               uuid
  #                                                              end))
  #   count = DocumentsManager.count()
  #
  #   Phoenix.Channel.push(socket,
  #                        "initialLoad",
  #                        %{"document-types": document_types,
  #                          "documents": documents,
  #                          "count": count})
  #   Enum.each(documents_ocr,
  #             fn %{:document_id => did, :ocr => ocr} ->
  #               {:ok, uuid} = Ecto.UUID.load(did)
  #               Phoenix.Channel
  #                      .push(socket,
  #                            "ocr",
  #                            %{document_id: uuid, ocr: ocr})
  #             end)
  #   {:noreply, socket}
  # end

  def handle_in(
        "document:comments",
        %{"comments" => comments, "document_id" => document_id},
        socket
      ) do
    {:ok, uuid} = Ecto.UUID.dump(document_id)

    %{comments: comments_updated, updated_at: updated} =
      DocumentsManager.edit_comments!(uuid, comments)

    Phoenix.Channel.push(
      socket,
      "comments",
      %{
        document_id: document_id,
        comments: comments_updated,
        updated_datetime: updated |> DocumentsManager.to_rfc2822()
      }
    )

    {:reply, :ok, socket}
  end

  def handle_in("documents:search", %{"query" => query}, socket) do
    Phoenix.Channel.push(
      socket,
      "searchResult",
      %{documents: DocumentsFinder.find(query) |> DocumentsManager.transform_to_viewmodels()}
    )

    {:reply, :ok, socket}
  end

  def handle_in("document:ocr", %{"document_id" => document_id}, socket) do
    {:ok, uuid} = document_id |> Ecto.UUID.dump()
    document = DocumentsManager.get_original!(uuid)
    %{document_id: did, mime_type: mime_type} = document
    absolute_documents_path = DocumentPath.document_path!(document)
    GenServer.cast(:ocr, {:process, did, absolute_documents_path, mime_type})
    {:reply, :ok, socket}
  end

  def handle_in("document:get", %{"document_id" => document_id}, socket) do
    {:ok, uuid} = document_id |> Ecto.UUID.dump()

    Phoenix.Channel.push(
      socket,
      "newDocument",
      DocumentsManager.get(uuid)
    )

    {:reply, :ok, socket}
  end

  def handle_in("documents:get", %{"offset" => offset, "length" => length}, socket) do
    documents = DocumentsManager.documents(offset, length)

    documents_ocr =
      DocumentsManager.ocr(
        documents
        |> Enum.map(fn %{"document_id" => x} ->
          {:ok, uuid} = Ecto.UUID.dump(x)
          uuid
        end)
      )

    count = DocumentsManager.count()

    Phoenix.Channel.push(
      socket,
      "newDocuments",
      %{documents: documents, count: count}
    )

    Enum.each(
      documents_ocr,
      fn %{:document_id => did, :ocr => ocr} ->
        {:ok, uuid} = Ecto.UUID.load(did)

        Phoenix.Channel.push(
          socket,
          "ocr",
          %{document_id: uuid, ocr: ocr}
        )
      end
    )

    {:reply, :ok, socket}
  end

  def handle_in("document:new_tag", %{"tag" => tag, "document_id" => document_id}, socket) do
    {:ok, uuid} = document_id |> Ecto.UUID.dump()
    TagManager.add_or_update!(uuid, tag)
    tags = TagManager.get_tags(uuid)

    Phoenix.Channel.push(
      socket,
      "newTags",
      %{document_id: document_id, tags: tags |> Enum.map(fn %{:name => tag} -> tag end)}
    )

    {:reply, :ok, socket}
  end

  def handle_in("document:delete_tag", %{"tag" => tag, "document_id" => document_id}, socket) do
    {:ok, uuid} = document_id |> Ecto.UUID.dump()
    TagManager.remove!(uuid, tag)
    tags = TagManager.get_tags(uuid)

    Phoenix.Channel.push(
      socket,
      "newTags",
      %{document_id: document_id, tags: tags |> Enum.map(fn %{:name => tag} -> tag end)}
    )

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

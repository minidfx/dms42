defmodule Dms42Web.DocumentsChannel do
  use Dms42Web, :channel
  require Logger
  alias Dms42.Models.DocumentType
  alias Dms42.Models.Document

  import Ecto.Query

  def join("documents:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("documents", %{"start" => start, "length" => length} = payload, socket) do
    send(self(), {:load_documents, start, length})
    {:noreply, socket}
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

  def handle_info({:load_documents, start, length}, socket) do
    documents =
      from(d in Document, limit: ^length, offset: ^start, order_by: d.inserted_at)
      |> Dms42.Repo.all()
      |> Enum.map(fn %{
                       :comments => comments,
                       :document_id => d_id,
                       :document_type_id => doc_type_id,
                       :inserted_at => inserted,
                       :updated_at => updated,
                       :file_path => file_path
                     } ->
        %{
          "insertedAt" => inserted |> to_rfc2822,
          "updatedAt" => updated |> to_rfc2822,
          "thumbnailPath" => file_path |> transform_to_frontend_url,
          "comments" => comments |> null_to_string,
          "document_id" => d_id,
          "document_type_id" => doc_type_id
        }
      end)

    result = %{
      "documents" => documents
    }

    Phoenix.Channel.push(socket, "documents", result)

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    document_types =
      DocumentType
      |> Dms42.Repo.all()
      |> Enum.map(fn %{:name => name, :type_id => type_id} -> %{"name" => name, "id" => type_id} end)

    Phoenix.Channel.push(socket, "documentTypes", %{
      "document_types" => document_types
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp transform_to_frontend_url(path), do: "/images/thumbnails/#{path}"

  defp null_to_string(string) when is_nil(string), do: ""
  defp null_to_string(string), do: string

  defp to_rfc2822(datetime) do
    {:ok, rfc2822} = Timex.format(datetime, "%a, %d %b %Y %H:%M:%S +0000", :strftime)
    rfc2822
  end
end

defmodule Dms42.QueueTags do
  @moduledoc false

  require Logger

  alias Dms42.TagManager

  #  Make sure this queue is sequential avoid concurrency while the user is adding or removing many in the same time.
  use Que.Worker, concurrency: 1

  def perform(document_id: document_id, tags: tags) do
    transaction_result =
      tags
      |> Enum.reduce(
        Ecto.Multi.new(),
        fn tag, transaction ->
          TagManager.add_or_update(transaction, document_id, tag)
        end
      )
      |> Dms42.Repo.transaction()

    case transaction_result do
      {:error, table, _, _} ->
        Logger.error("Was not able to add the new tags into the table #{table}.")

      {:error, _} ->
        Logger.error("Was not able to add the new tags.")

      {:ok, _} ->
        Logger.info("Tags successfully added to the document #{document_id}.")
    end
  end

  def enqueue_new_tags(document_id, tags) do
    Que.add(Dms42.QueueTags, document_id: document_id, tags: tags)
  end
end

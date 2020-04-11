defmodule Dms42.QueueState do
  use Agent

  require Logger

  def start_link() do
    Temp.track!()
    Agent.start_link(fn -> initial_state() end, name: __MODULE__)
  end

  def stop(agent, reason) do
    IO.inspect(reason)
    queue = Agent.get(agent, fn x -> Map.get(x, :queue, :not_found) end)

    case queue do
      :not_found -> Logger.warn("Was not able to stop the queue because it was not found.")
      x -> OPQ.stop(x)
    end
  end

  def enqueue_document(
        original_file_name,
        mime_type,
        original_file_datetime,
        document_type,
        tags,
        bytes
      ) do
    queue = Agent.get(__MODULE__, fn x -> Map.get(x, :queue) end)

    Logger.info("Queuing a new job for the document #{original_file_name} ...")

    OPQ.enqueue(
      queue,
      Dms42.DocumentsProcessor,
      :process,
      [original_file_name, mime_type, original_file_datetime, document_type, tags, bytes]
    )
  end

  defp initial_state do
    {:ok, queue} =
      OPQ.init(
        name: :queue_documents,
        workers: :erlang.system_info(:logical_processors_available),
        timeout: 60_000 * 15
      )

    %{
      queue: queue
    }
  end
end

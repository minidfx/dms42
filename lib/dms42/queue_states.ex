defmodule Dms42.QueueState do
  use Agent
  
  require Logger

  def start_link() do
    Logger.debug("Starting the #{__MODULE__} ...")
    Agent.start_link(fn -> initial_state() end, name: __MODULE__)
  end
  
  def stop(agent, reason) do
    IO.inspect(reason)
    queue = Agent.get(:queue_document, fn x -> Map.get(x, :queue, :not_found) end)
    case queue do
      :not_found -> Logger.warn("Was not able to stop the queue because it was not found.")
      x -> OPQ.stop(x)
    end
  end

  def get_documents_path() do
    Agent.get(__MODULE__, fn x -> Map.get(x, :documents_path, :not_found) end)
  end

  def get_thumbnails_path() do
    Agent.get(__MODULE__, fn x -> Map.get(x, :thumbnails_path, :not_found) end)
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
    {:ok, queue} = OPQ.init(name: :queue_documents, workers: 1, interval: 500, timeout: 60_000 * 15)
    %{
      thumbnails_path: Application.get_env(:dms42, :thumbnails_path) |> Path.absname(),
      documents_path: Application.get_env(:dms42, :documents_path) |> Path.absname(),
      queue: queue 
    }
  end
end

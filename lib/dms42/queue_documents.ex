defmodule Dms42.QueueDocuments do
  @moduledoc false

  use Que.Worker, concurrency: Application.get_env(:dms42, :queue_documents_concurrency)

  def on_setup(_job) do
    Dms42.States.increment_jobs(:processing)
  end
  
  def on_teardown(_job) do
    Dms42.States.decrement_jobs(:processing)
  end

  def perform({original_file_name, mime_type, original_file_datetime, document_type, tags, bytes}) do
    Dms42.DocumentsProcessor.process(
      original_file_name,
      mime_type,
      original_file_datetime,
      document_type,
      tags,
      bytes
    )
  end

  def enqueue_document(
        original_file_name,
        mime_type,
        original_file_datetime,
        document_type,
        tags,
        bytes
      ) do
    Dms42.States.increment_jobs(:queued)

    Que.add(
      Dms42.QueueDocuments,
      {original_file_name, mime_type, original_file_datetime, document_type, tags, bytes}
    )
  end

  @spec info() :: Dms42.Models.QueueInfo.t()
  def info() do
    {queued, processing} = Dms42.States.get_jobs_status()

    %Dms42.Models.QueueInfo{
      workers: Application.get_env(:dms42, :queue_documents_concurrency),
      pending: queued,
      processing: processing
    }
  end
end

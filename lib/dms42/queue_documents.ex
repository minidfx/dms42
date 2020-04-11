defmodule Dms42.QueueDocuments do
  @moduledoc false

  use Que.Worker, concurrency: Application.get_env(:dms42, :queue_documents_concurrency)

  def on_setup(_job) do
    Dms42.States.increment_jobs(:processing)
  end

  def on_teardown(_job) do
    Dms42.States.decrement_jobs(:processing)
  end

  def perform(
        original_file_name: original_file_name,
        mime_type: mime_type,
        original_file_datetime: original_file_datetime,
        document_type: document_type,
        tags: tags,
        file: bytes
      ) do
    Dms42.DocumentsProcessor.process(
      original_file_name,
      mime_type,
      original_file_datetime,
      document_type,
      tags,
      bytes
    )
  end

  def perform(
        document: document,
        thumbnail: _
      ) do
    Dms42.ThumbnailProcessor.process(document)
  end

  def perform(
        document: document,
        ocr: _
      ) do
    Dms42.OcrProcessor.process(document)
  end

  @spec enqueue_thumbnail(Dms42.Models.Document.t()) :: :ok
  def enqueue_thumbnail(document) do
    Dms42.States.increment_jobs(:queued)

    Que.add(
      Dms42.QueueDocuments,
      document: document,
      thumbnail: true
    )
  end

  @spec enqueue_ocr(Dms42.Models.Document.t()) :: :ok
  def enqueue_ocr(document) do
    Dms42.States.increment_jobs(:queued)

    Que.add(
      Dms42.QueueDocuments,
      document: document,
      ocr: true
    )
  end

  @spec enqueue_document(String.t(), String.t(), String.t(), String.t(), list(String.t()), binary) ::
          :ok
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
      original_file_name: original_file_name,
      mime_type: mime_type,
      original_file_datetime: original_file_datetime,
      document_type: document_type,
      tags: tags,
      file: bytes
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

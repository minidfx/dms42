defmodule Dms42.DocumentManager do

  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr

  alias Dms42.TagManager
  alias Dms42.TransactionHelper
  alias Dms42.DocumentPath

  import Ecto.Query, only: [from: 2]

  @doc """
    Add the document processing the OCR and saving it.
  """
  @spec add(file_name :: String.t(), mime_type :: String.t(), original_file_datetime :: DateTime.t(), document_type :: String.t(), tags :: list(String.t()), bytes :: binary) :: :ok
  def add(file_name, mime_type, original_file_datetime, document_type, tags, bytes) do
    # FIXME: Should be sync to return the error to the caller directly.
    GenServer.cast(:documents_processor, {:process,
                                          file_name,
                                          mime_type,
                                          original_file_datetime,
                                          document_type,
                                          tags,
                                          bytes})
  end

  @doc """
    Removes the document from the database, the storage and its associated data.
  """
  @spec remove!(document_id :: binary) :: no_return()
  def remove!(document_id) do
    document = Document |> Dms42.Repo.get_by!(document_id: document_id)
    document_path = DocumentPath.document_path!(document)
    temp_file_path = Temp.path!
    File.rename(document_path, temp_file_path)
    try do
      Ecto.Multi.new() |> TagManager.clean_document_tags(document_id)
                       |> Ecto.Multi.delete_all("delete_ocr", (from DocumentOcr, where: [document_id: ^document_id])) 
                       |> Ecto.Multi.delete("delete_document", document)
                       |> TransactionHelper.commit!
      File.rm!(temp_file_path)
    rescue
      e ->
        File.rename(temp_file_path, document_path)
        IO.inspect(e)
    end
  end

  @doc """
    Edits the document comments.
  """
  @spec edit_comment!(comments :: String.t()) :: no_return()
  def edit_comment!(comments) do
    Dms42.Repo.update!(Document.changeset(%Document{}, %{comments: comments}))
  end

end

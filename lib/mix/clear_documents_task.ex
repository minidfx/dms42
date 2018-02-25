defmodule Mix.Tasks.Clear.Documents do
  use Mix.Task

  require Logger

  alias Dms42.DocumentPath

  def run(_) do
    documents_path = DocumentPath.document_folder_path!()
    Logger.info("Will remove the folder #{documents_path}.")
    documents_path |> File.rm_rf!

    thumbnails_path = DocumentPath.thumbnail_folder_path!()
    Logger.info("Will remove the folder #{thumbnails_path}.")
    thumbnails_path |> File.rm_rf!
  end

  def task_name(_), do: "clear.documents"
end

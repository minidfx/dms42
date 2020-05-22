defmodule Dms42.DocumentPath do
  use Agent

  alias Dms42.Models.Document

  @doc false
  def start_link(), do: Agent.start_link(fn -> initial_state() end, name: __MODULE__)

  @doc """
    Ensures that the thumbnails folder of the document exists.
  """
  @spec ensure_thumbnails_folder_exists!(Dms42.Models.Document.t()) :: :ok
  def ensure_thumbnails_folder_exists!(document) when is_map(document) do
    folder_path = to_path!(:absolute_thumbnail_path, document)

    case folder_path |> File.exists?() do
      true -> :ok
      false -> File.mkdir_p!(folder_path)
    end
  end

  @doc """
    Ensures that the document folder exists.
  """
  @spec ensure_document_folder_exists!(Dms42.Models.Document.t()) :: :ok
  def ensure_document_folder_exists!(document) when is_map(document) do
    folder_path = Path.join([get!(:absolute_document_path), middle_path!(document)])

    case folder_path |> File.exists?() do
      true -> :ok
      false -> File.mkdir_p!(folder_path)
    end
  end

  @doc """
    Returns the path of the document.
  """
  @spec document_path!(Dms42.Models.Document.t()) :: String.t()
  def document_path!(document) when is_map(document),
    do: to_path!(:absolute_document_path, document)

  @doc """
    Returns the small thumbnail path of the document.
  """
  @spec small_thumbnail_path!(Dms42.Models.Document.t()) :: String.t()
  def small_thumbnail_path!(document) when is_map(document),
    do: Path.join([to_path!(:absolute_thumbnail_path, document), "small.png"])

  @doc """
    Returns the first big thumbnail path of the document.
  """
  @spec big_first_thumbnail_path!(Dms42.Models.Document.t()) :: String.t()
  def big_first_thumbnail_path!(document) when is_map(document),
    do: Path.join([to_path!(:absolute_thumbnail_path, document), "big-0.png"])

  @doc """
    Returns the big thumbnail paths of the document.
  """
  @spec big_thumbnail_paths!(Dms42.Models.Document.t()) :: list(String.t())
  def big_thumbnail_paths!(document) when is_map(document),
    do: to_path!(:absolute_thumbnail_path, document) |> list_big_thumbnails

  @doc """
    Returns the big thumbnail paths pattern for the futures page of the documents passing the document.
  """
  @spec big_thumbnail_paths_pattern!(Dms42.Models.Document) :: String.t()
  def big_thumbnail_paths_pattern!(document) when is_map(document),
    do: Path.join([to_path!(:absolute_thumbnail_path, document), "big-%0d.png"])

  @doc """
    Returns the big thumbnail paths pattern for the futures page of the documents passing base path.
  """
  @spec big_thumbnail_paths_pattern!(String.t()) :: String.t()
  def big_thumbnail_paths_pattern!(base_path) when is_bitstring(base_path),
    do: Path.join([base_path, "big-%0d.png"])

  @doc """
    Returns the absolute path of the folder containing documents.
  """
  @spec document_folder_path!() :: String.t()
  def document_folder_path!(), do: get!(:absolute_document_path)

  @doc """
    Returns the absolute path of the folder containing thumbnails.
  """
  @spec thumbnail_folder_path!() :: String.t()
  def thumbnail_folder_path!(), do: get!(:absolute_thumbnail_path)

  @doc """
    Returns the absolute path of the document folder containing thumbnails.
  """
  @spec thumbnail_folder_path!(Dms42.Models.Document.t()) :: String.t()
  def thumbnail_folder_path!(document), do: to_path!(:absolute_thumbnail_path, document)

  @spec list_big_thumbnails(String.t()) :: list(String.t())
  def list_big_thumbnails(path) do
    case File.exists?(path) do
      false ->
        []

      true ->
        path
        |> File.ls!()
        |> Enum.map(fn x -> x |> Path.absname(path) end)
        |> Enum.map(fn x -> {Path.basename(x), x} end)
        |> Enum.map(fn {x, y} -> {Regex.run(~r/big-(\d+)\.png$/, x), y} end)
        |> Enum.filter(fn {x, _} -> x != nil end)
        |> Enum.map(fn {[_, index], x} -> {index |> String.to_integer(), x} end)
        |> Enum.sort_by(fn {x, _} -> x end)
        |> Enum.map(fn {_, x} -> x end)
    end
  end

  ##### Private members

  @spec initial_state() :: map()
  defp initial_state() do
    relative_document_path = Application.get_env(:dms42, :documents_path)
    relative_thumbnail_path = Application.get_env(:dms42, :thumbnails_path)

    %{
      relative_document_path: relative_document_path,
      relative_thumbnail_path: relative_thumbnail_path,
      absolute_document_path: relative_document_path |> Path.absname(),
      absolute_thumbnail_path: relative_thumbnail_path |> Path.absname()
    }
  end

  @spec get!(atom()) :: String.t()
  defp get!(key) when is_atom(key) do
    case Agent.get(__MODULE__, fn x -> Map.get(x, key, :not_found) end) do
      :not_found -> raise "The key was not found: #{Atom.to_string(key)}"
      x -> x
    end
  end

  @spec uuid!(Dms42.Models.Document.t()) :: String.t()
  defp uuid!(document) when is_map(document) do
    %Document{:document_id => document_id} = document

    case Ecto.UUID.load(document_id) do
      {:ok, x} -> x
      :error -> raise "Was not able to convert the document id to a string"
    end
  end

  @spec middle_path!(Dms42.Models.Document.t()) :: String.t()
  defp middle_path!(document) when is_map(document) do
    %Document{:inserted_at => datetime} = document
    %{:year => year, :month => month, :day => day} = datetime

    Path.join([
      Integer.to_string(year),
      Integer.to_string(month),
      Integer.to_string(day)
    ])
  end

  @spec to_path!(atom(), Dms42.Models.Document.t()) :: String.t()
  defp to_path!(prefix_key, document) do
    Path.join([
      get!(prefix_key),
      middle_path!(document),
      uuid!(document)
    ])
  end
end

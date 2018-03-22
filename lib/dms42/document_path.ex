defmodule Dms42.DocumentPath do
  alias Dms42.Models.Document

  def start_link(), do: GenServer.start(__MODULE__, %{}, name: :document_path)

  def init(args) do
    relative_document_path = Application.get_env(:dms42, :documents_path)
    relative_thumbnail_path = Application.get_env(:dms42, :thumbnails_path)
    {:ok,
      args
      |> Map.put(:absolute_document_path, relative_document_path |> Path.absname)
      |> Map.put(:absolute_thumbnail_path, relative_thumbnail_path |> Path.absname)
      |> Map.put(:relative_document_path, relative_document_path)
      |> Map.put(:relative_thumbnail_path, relative_thumbnail_path)
    }
  end

  def terminate(reason, _), do: IO.inspect(reason)

  @callback handle_call({:relative_document_path, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call(:relative_document_path,
                  _from,
                  %{:relative_document_path => path} = state) do
    {:reply, {:ok, path}, state}
  end

  @callback handle_call({:relative_thumbnail_path, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call(:relative_thumbnail_path,
                  _from,
                  %{:relative_thumbnail_path => path} = state) do
    {:reply, {:ok, path}, state}
  end

  @callback handle_call({:relative_document_path, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:relative_document_path, document_id},
                   _from,
                   %{:relative_document_path => path} = state) when is_bitstring(document_id) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    document_path = Path.join([path,
                               year |> Integer.to_string,
                               month |> Integer.to_string,
                               day |> Integer.to_string,
                               document_id])
    {:reply, {:ok, document_path}, state}
  end

  @callback handle_call({:relative_thumbnail_path, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:relative_thumbnail_path, document_id},
                   _from,
                   %{:relative_thumbnail_path => path} = state) when is_bitstring(document_id) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    document_path = Path.join([path,
                               year |> Integer.to_string,
                               month |> Integer.to_string,
                               day |> Integer.to_string,
                               document_id])
    {:reply, {:ok, document_path}, state}
  end


  @callback handle_call({:document_path, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:document_path, %Document{:inserted_at => nil}},
                   _from,
                   state) do
    {:reply, {:error, "The document doesn't contains a valid inserted datetime."}, state}
  end
  def handle_call({:document_path, %Document{:document_id => document_id, :inserted_at => datetime}},
                   _from,
                   %{:absolute_document_path => absolute_document_path} = state) do
      %{:year => year, :month => month, :day => day} = datetime
      {:ok, uuid} = Ecto.UUID.load(document_id)
      document_path = Path.join([absolute_document_path,
                                 year |> Integer.to_string,
                                 month |> Integer.to_string,
                                 day |> Integer.to_string,
                                 uuid])
    {:reply, {:ok, document_path}, state}
  end

  @callback handle_call({:document_path, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:document_path, document_id},
                   _from,
                   %{:absolute_document_path => path} = state) when is_bitstring(document_id) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    document_path = Path.join([path,
                               year |> Integer.to_string,
                               month |> Integer.to_string,
                               day |> Integer.to_string,
                               document_id])
    {:reply, {:ok, document_path}, state}
  end

  @callback handle_call({:small_thumbnail_path, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:small_thumbnail_path, document_id},
                   _from,
                   %{:absolute_thumbnail_path => path} = state) when is_bitstring(document_id) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    small_thumbnail_path = Path.join([path,
                                      year |> Integer.to_string,
                                      month |> Integer.to_string,
                                      day |> Integer.to_string,
                                      document_id,
                                      "small.png"])
    {:reply, {:ok, small_thumbnail_path}, state}
  end

  @callback handle_call({:small_thumbnail_path, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:small_thumbnail_path, %Document{:document_id => document_id, :inserted_at => datetime}},
                   _from,
                   %{:absolute_thumbnail_path => path} = state) do
    %{:year => year, :month => month, :day => day} = datetime
    {:ok, uuid} = Ecto.UUID.load(document_id)
    small_thumbnail_path = Path.join([path,
                                      year |> Integer.to_string,
                                      month |> Integer.to_string,
                                      day |> Integer.to_string,
                                      uuid,
                                      "small.png"])
    {:reply, {:ok, small_thumbnail_path}, state}
  end

  @callback handle_call({:big_thumbnail_paths, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:big_thumbnail_paths, %Document{:document_id => document_id,
                                                   :inserted_at => datetime,
                                                   :mime_type => "application/pdf"}},
                   _from,
                   %{:absolute_thumbnail_path => path} = state) do
    case datetime do
      nil -> {:reply, {:error, "The document doesn't contain valid datetime."}, state}
      x ->
        {:ok, uuid} = Ecto.UUID.load(document_id)
        %{:year => year, :month => month, :day => day} = x
        thumbnail_folder_path = Path.join([path,
                                           year |> Integer.to_string,
                                           month |> Integer.to_string,
                                           day |> Integer.to_string,
                                           uuid])
        files = thumbnail_folder_path
        |> File.ls!
        |> Enum.map(fn x -> x |> Path.absname(thumbnail_folder_path) end)
        |> Enum.map(fn x -> {Path.basename(x), x} end)
        |> Enum.map(fn {x, y} -> {Regex.run(~r/big-(\d+)\.png$/, x), y} end)
        |> Enum.filter(fn {x, _} -> x != nil end)
        |> Enum.map(fn {[_, index], x} -> {index |> String.to_integer, x} end)
        |> Enum.sort_by(fn {x, _} -> x end)
        |> Enum.map(fn {_, x} -> x end)
        {:reply, {:ok, files}, state}
    end
  end

  @callback handle_call({:big_thumbnail_paths, document :: Document}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:big_thumbnail_paths, %Document{:document_id => document_id,
                                                   :inserted_at => datetime}},
                   _from,
                   %{:absolute_document_path => path} = state) do
    case datetime do
      nil -> {:reply, {:error, "The document doesn't contain valid datetime."}, state}
      x ->
        {:ok, uuid} = Ecto.UUID.load(document_id)
        %{:year => year, :month => month, :day => day} = x
        document_file_path = Path.join([path,
                                        year |> Integer.to_string,
                                        month |> Integer.to_string,
                                        day |> Integer.to_string,
                                        uuid])
        {:reply, {:ok, [document_file_path]}, state}
    end
  end

  @callback handle_call({:big_thumbnail_paths, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call({:big_thumbnail_paths, document_id},
                   _from,
                   %{:absolute_thumbnail_path => path} = state) when is_bitstring(document_id) do
    %{:year => year, :month => month, :day => day} = DateTime.utc_now()
    thumbnail_folder_path = Path.join([path,
                                       year |> Integer.to_string,
                                       month |> Integer.to_string,
                                       day |> Integer.to_string,
                                       document_id])
    files = thumbnail_folder_path
    |> File.ls!
    |> Enum.map(fn x -> x |> Path.absname(thumbnail_folder_path) end)
    |> Enum.map(fn x -> {Path.basename(x), x} end)
    |> Enum.map(fn {x, y} -> {Regex.run(~r/big-(\d+)\.png$/, x), y} end)
    |> Enum.filter(fn {x, _} -> x != nil end)
    |> Enum.map(fn {[_, index], x} -> {index |> String.to_integer, x} end)
    |> Enum.sort_by(fn {x, _} -> x end)
    |> Enum.map(fn {_, x} -> x end)
    {:reply, {:ok, files}, state}
  end

  @callback handle_call({:big_thumbnail_paths, document_id :: String.t()}, from :: any, state :: map) :: {:reply, String.t(), state :: map}
  def handle_call(:absolute_thumbnail_path,
                  _from,
                  %{:absolute_thumbnail_path => path} = state),
   do: {:reply, {:ok, path}, state}

  @callback handle_call(:absolute_document_path, from :: any,  state :: map) :: {:reply, String.t(), state :: map}
  def handle_call(:absolute_document_path,
                  _from,
                  %{:absolute_document_path => path} = state),
    do: {:reply, {:ok, path}, state}

  @doc """
    Returns the path of the document.
  """
  @spec document_path!(Document) :: String.t()
  def document_path!(document) when is_map(document) do
    case GenServer.call(:document_path, {:document_path, document}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the path of the document.
  """
  @spec document_path!(document_id :: String.t()) :: String.t()
  def document_path!(document_id) when is_bitstring(document_id) do
    case GenServer.call(:document_path, {:document_path, document_id}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the small thumbnail path of the document.
  """
  @spec small_thumbnail_path!(Document) :: String.t()
  def small_thumbnail_path!(%Document{} = document) do
    case GenServer.call(:document_path, {:small_thumbnail_path, document}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the small thumbnail path of the document.
  """
  @spec small_thumbnail_path!(document_id :: String.t()) :: String.t()
  def small_thumbnail_path!(document_id) when is_bitstring(document_id) do
    case GenServer.call(:document_path, {:small_thumbnail_path, document_id}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the big thumbnail paths of the document.
  """
  @spec big_thumbnail_paths!(Document) :: list(String.t())
  def big_thumbnail_paths!(document) when is_map(document) do
    case GenServer.call(:document_path, {:big_thumbnail_paths, document}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the big thumbnail paths of the document.
  """
  @spec big_thumbnail_paths!(document_id :: String.t()) :: list(String.t())
  def big_thumbnail_paths!(document_id) when is_bitstring(document_id) do
    case GenServer.call(:document_path, {:big_thumbnail_paths, document_id}) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the absolute path of the folder containing documents.
  """
  @spec document_folder_path!() :: String.t()
  def document_folder_path!() do
    case GenServer.call(:document_path, :absolute_document_path) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the absolute path of the folder containing thumbnails.
  """
  @spec thumbnail_folder_path!() :: String.t()
  def thumbnail_folder_path!() do
    case GenServer.call(:document_path, :absolute_thumbnail_path) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the relative path of the folder containing thumbnails.
  """
  @spec thumbnail_folder_relative_path!() :: String.t()
  def thumbnail_folder_relative_path!() do
    case GenServer.call(:document_path, :relative_thumbnail_path) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end

  @doc """
    Returns the relative path of the folder containing documents.
  """
  @spec document_folder_relative_path!() :: String.t()
  def document_folder_relative_path!() do
    case GenServer.call(:document_path, :relative_document_path) do
      {:error, reason} -> raise(reason)
      {:ok, x} -> x
    end
  end
end

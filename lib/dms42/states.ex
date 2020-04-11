defmodule Dms42.States do
  @moduledoc false

  use Agent

  def start_link() do
    Temp.track!()
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec increment_jobs(:queued) :: :ok
  def increment_jobs(:queued),
    do: Agent.update(__MODULE__, fn x -> Map.update(x, :jobs, 1, fn y -> y + 1 end) end)

  @spec increment_jobs(:processing) :: :ok
  def increment_jobs(:processing),
    do:
      Agent.update(__MODULE__, fn x ->
        Map.update(x, :jobs_processing, 1, fn y -> y + 1 end)
        |> Map.update(:jobs, 1, fn y -> Kernel.max(0, y - 1) end)
      end)

  @spec decrement_jobs(:processing) :: :ok
  def decrement_jobs(:processing),
    do:
      Agent.update(__MODULE__, fn x ->
        Map.update(x, :jobs_processing, 1, fn y -> Kernel.max(0, y - 1) end)
      end)

  @spec get_jobs_status() :: {integer, integer}
  def get_jobs_status() do
    Agent.get(
      __MODULE__,
      fn x ->
        {Map.get(x, :jobs, 0), Map.get(x, :jobs_processing, 0)}
      end
    )
  end
end

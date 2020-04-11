defmodule Dms42.Models.QueueInfo do
  @enforce_keys [:workers, :pending, :processing]

  defstruct [:workers, :pending, :processing]
end

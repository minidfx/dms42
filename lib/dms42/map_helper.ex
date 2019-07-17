defmodule Dms42.MapHelper do
  @spec put_if(map(), any(), (() -> any()), true|false) :: map()
  def put_if(map, key, value, true) when is_map(map) and is_function(value, 0), do: map |> Map.put(key, value.())
  def put_if(map, _, value, false) when is_map(map) and is_function(value, 0), do: map
end

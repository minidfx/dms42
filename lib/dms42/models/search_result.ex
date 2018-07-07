defmodule Dms42.Models.SearchResult do
  @enforce_keys [:document_id, :document, :ranking]

  defstruct [:document_id, :document, :ranking]
end

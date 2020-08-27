defmodule Dms42.Models.SearchResult do
  @enforce_keys [:document_id, :document, :ranking, :datetime]

  defstruct [:document_id, :document, :ranking, :datetime]
end

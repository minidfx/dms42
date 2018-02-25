defmodule Dms42.Models.NewDocumentProcessingContext do
  @enforce_keys [:document, :transaction]

  defstruct [:document, :ocr, :tags, :type, :transaction]
end

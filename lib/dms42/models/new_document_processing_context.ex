defmodule Dms42.Models.NewDocumentProcessingContext do
  @enforce_keys [:document, :transaction, :tags, :content]

  defstruct [:document, :ocr, :tags, :type, :transaction, :tags, :content]
end

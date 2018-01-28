defmodule Dms42.Models.NewDocumentProcessingContext do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.DocumentType

  @enforce_keys [:document, :transaction]

  defstruct [:document, :ocr, :tags, :type, :transaction]
end

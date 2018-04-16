defmodule Dms42.DocumentPath.DocumentsFinder do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag

  import Ecto.Query, only: [from: 2]

  @spec find(query :: String.t) :: list(Document)
  def find(query) when is_bitstring(query) do
    exact_match = find_exact_match(query) |> Dms42.Repo.all
                                          |> MapSet.new
    term_match = query |> String.split(" ")
                       |> find_by_terms
                       |> MapSet.new
    MapSet.union(exact_match, term_match)
  end

  @spec find_by_terms(terms :: list(String.t())) :: list(Document)
  defp find_by_terms(terms) when is_list(terms),
    do: terms |> Enum.map(&find_by_term/1)
              |> Enum.map(&Dms42.Repo.all/1)
              |> Enum.flat_map(fn x -> x end)

  @spec find_by_term(term :: String.t()) :: list(Document)
  defp find_by_term(term) do
    from d in Document,
    left_join: o in DocumentOcr, on: d.document_id == o.document_id,
    left_join: dt in DocumentTag, on: d.document_id == dt.document_id,
    left_join: t in Tag, on: t.tag_id == dt.tag_id,
    where: ilike(d.comments, ^"%#{term}%"),
    or_where: ilike(d.original_file_name, ^"%#{term}%"),
    or_where: ilike(o.ocr, ^"%#{term}%"),
    or_where: t.name == ^term,
    select: d
  end

  @spec find_exact_match(query :: String.t()) :: list(Document)
  defp find_exact_match(query) do
    from d in Document,
    left_join: o in DocumentOcr, on: d.document_id == o.document_id,
    left_join: dt in DocumentTag, on: d.document_id == dt.document_id,
    left_join: t in Tag, on: t.tag_id == dt.tag_id,
    where: ilike(d.comments, ^"%#{query}%"),
    or_where: ilike(d.original_file_name, ^"%#{query}%"),
    or_where: ilike(o.ocr, ^"%#{query}%"),
    or_where: t.name == ^query,
    select: d
  end
end

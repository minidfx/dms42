defmodule Dms42.DocumentsFinder do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag

  import Ecto.Query, only: [from: 2]

  @max_result 10

  @spec find(query :: String.t) :: list(Document)
  def find(query) when is_bitstring(query) do
    exact_match = find_exact_match(query |> normalize) |> MapSet.new
    term_match = query |> String.split(" ")
                       |> find_by_terms
                       |> MapSet.new
    MapSet.union(exact_match, term_match)
  end

  @spec normalize(term :: String.t()) :: String.t()
  def normalize(term),
    do: term |> String.normalize(:nfd)
             |> String.replace(~r/[^A-Za-z\s]/u, "")

  @spec find_by_terms(terms :: list(String.t())) :: list(Document)
  defp find_by_terms(terms) when is_list(terms),
    do: terms |> Enum.map(fn x -> x |> normalize |> find_by_term end)
              |> Enum.map(&Dms42.Repo.all/1)
              |> Enum.flat_map(fn x -> x end)

  @spec find_by_term(term :: String.t()) :: list(Document)
  defp find_by_term(term) do
    from d in Document,
    left_join: o in DocumentOcr, on: d.document_id == o.document_id,
    left_join: dt in DocumentTag, on: d.document_id == dt.document_id,
    left_join: t in Tag, on: t.tag_id == dt.tag_id,
    where: ilike(d.comments, ^"%#{term}%"),
    or_where: ilike(d.original_file_name_normalized, ^"%#{term}%"),
    or_where: ilike(o.ocr_normalized, ^"%#{term}%"),
    or_where: t.name == ^term,
    limit: @max_result,
    select: d
  end

  @spec find_exact_match(query :: String.t()) :: list(Document)
  defp find_exact_match(query) do
    query = from d in Document,
            left_join: o in DocumentOcr, on: d.document_id == o.document_id,
            left_join: dt in DocumentTag, on: d.document_id == dt.document_id,
            left_join: t in Tag, on: t.tag_id == dt.tag_id,
            where: ilike(d.comments, ^"%#{query}%"),
            or_where: ilike(d.original_file_name_normalized, ^"%#{query}%"),
            or_where: ilike(o.ocr_normalized, ^"%#{query}%"),
            or_where: t.name == ^query,
            limit: @max_result,
            select: d
    Dms42.Repo.all query
  end
end

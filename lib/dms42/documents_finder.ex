defmodule Dms42.DocumentsFinder do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.Models.SearchResult

  import Ecto.Query, only: [from: 2]

  @max_result 20

  def find(""), do: []

  def find(query) when is_bitstring(query) do
    exact_match = query |> normalize |> find_exact_match |> transform_to_map

    term_match =
      query
      |> String.split(" ")
      |> find_by_terms
      |> transform_to_map

    result = Map.merge(term_match, exact_match)

    result
    |> Map.values()
    |> Enum.sort_by(fn %SearchResult{:ranking => x} -> x end)
    |> Enum.map(fn %SearchResult{:document => x} -> x end)
  end

  def normalize(""), do: ""

  def normalize(term),
    do:
      term
      |> String.normalize(:nfd)
      |> String.replace(~r/[^A-Za-z\s]/u, "")

  defp find_by_terms(terms) when is_list(terms),
    do:
      terms
      |> Enum.map(fn x -> x |> normalize |> find_by_term end)
      |> Enum.map(&Dms42.Repo.all/1)
      |> Enum.flat_map(fn x -> x end)
      |> Enum.map(fn x -> to_search_result(x, 2) end)

  defp find_by_term(term) do
    from(d in Document,
      left_join: o in DocumentOcr,
      on: d.document_id == o.document_id,
      left_join: dt in DocumentTag,
      on: d.document_id == dt.document_id,
      left_join: t in Tag,
      on: t.tag_id == dt.tag_id,
      where: ilike(d.comments, ^"%#{term}%"),
      or_where: ilike(d.original_file_name_normalized, ^"%#{term}%"),
      or_where: ilike(o.ocr_normalized, ^"%#{term}%"),
      or_where: t.name == ^term,
      limit: @max_result,
      select: d
    )
  end

  defp find_exact_match(query) do
    query =
      from(d in Document,
        left_join: o in DocumentOcr,
        on: d.document_id == o.document_id,
        left_join: dt in DocumentTag,
        on: d.document_id == dt.document_id,
        left_join: t in Tag,
        on: t.tag_id == dt.tag_id,
        where: ilike(d.comments, ^"%#{query}%"),
        or_where: ilike(d.original_file_name_normalized, ^"%#{query}%"),
        or_where: ilike(o.ocr_normalized, ^"%#{query}%"),
        or_where: t.name == ^query,
        limit: @max_result,
        select: d
      )

    Dms42.Repo.all(query) |> Enum.map(fn x -> to_search_result(x, 1) end)
  end

  defp to_search_result(%Document{:document_id => did} = document, ranking) do
    %SearchResult{document_id: did, document: document, ranking: ranking}
  end

  defp transform_to_map(searchResults) do
    Enum.map(
      searchResults,
      fn %SearchResult{:document_id => did} = x ->
        {did, x}
      end
    )
    |> Map.new()
  end
end

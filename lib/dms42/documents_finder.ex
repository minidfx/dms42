defmodule Dms42.DocumentPath.DocumentsFinder do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr

  import Ecto.Query, only: [from: 2]

  @spec find(query :: String.t) :: list(Document)
  def find(query) when is_bitstring(query) do
    exact_match = find_exact_match(query)
    term_match = query |> String.split(" ")
                       |> find_by_terms
    Enum.concat(exact_match, term_match)
  end

  @spec find_by_terms(terms :: list(String.t())) :: list(Document)
  defp find_by_terms(terms) when is_list(terms), do: find_by_terms(terms, [])
  defp find_by_terms([], acc), do: acc
  defp find_by_terms([head|tail], acc), do: find_by_terms(tail, find_by_term(head) ++ acc)

  @spec find_by_term(term :: String.t()) :: list(Document)
  defp find_by_term(term) do
    from d in Document,
    left_join: o in DocumentOcr, on: d.document_id == o.document_id,
    where: ilike(d.comments, ^"%#{term}%"),
    or_where: ilike(d.original_file_name, ^"%#{term}%"),
    or_where: ilike(o.ocr, ^"%#{term}%"),
    select: d
  end

  @spec find_exact_match(query :: String.t()) :: list(Document)
  defp find_exact_match(query) do
    from d in Document,
    left_join: o in DocumentOcr, on: d.document_id == o.document_id,
    where: ilike(d.comments, ^"%#{query}%"),
    or_where: ilike(d.original_file_name, ^"%#{query}%"),
    or_where: ilike(o.ocr, ^"%#{query}%"),
    select: d
  end
end

defmodule Dms42.DocumentsFinder do
  alias Dms42.Models.Document
  alias Dms42.Models.DocumentOcr
  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.Models.SearchResult

  import Ecto.Query, only: [from: 2, where: 3, order_by: 3, limit: 3, select: 3]
  import Ecto.Query.API, only: [ilike: 2, and: 2]

  @max_result 20

  @spec find(String.t()) :: list(Dms42.Models.Document.t())
  def find(""), do: []

  @spec find(String.t()) :: list(Dms42.Models.SearchResult.t())
  def find(query) when is_bitstring(query) do
    query
    |> normalize
    |> find_by_exact_tags
    |> find_by_partial_tags
    |> find_by_exact_comments
    |> find_by_exact_ocr
    |> find_by_partial_ocr
    |> to_result
    |> Enum.sort_by(fn %SearchResult{:ranking => x} -> x end)
    |> Enum.uniq_by(fn %SearchResult{:document_id => x} -> x end)
  end

  @spec normalize(String.t()) :: String.t()
  def normalize(""), do: ""

  @spec normalize(String.t()) :: String.t()
  def normalize(term),
    do:
      term
      |> String.normalize(:nfd)
      |> String.replace(~r/[^A-Za-z0-9_\s]/u, "")
      |> String.trim()

  ##### Private members

  @spec to_result({String.t(), list}) :: list
  defp to_result({_, result}), do: result

  @spec find_by_exact_tags(String.t()) :: {String.t(), list(Dms42.Models.Document.t())}
  defp find_by_exact_tags(query) do
    result =
      query
      |> String.split(" ")
      |> Enum.map(fn x -> x |> normalize |> query_find_by_exact_tag end)
      |> Enum.map(&Dms42.Repo.all/1)
      |> Enum.flat_map(fn x -> x end)
      |> Enum.map(fn x -> to_search_result(x, 1) end)

    {query, result}
  end

  @spec find_by_partial_tags(String.t()) :: {String.t(), list(Dms42.Models.Document.t())}
  defp find_by_partial_tags({query, acc}) when length(acc) >= @max_result, do: {query, acc}

  defp find_by_partial_tags({query, acc}) do
    result =
      query
      |> String.split(" ")
      |> Enum.map(fn x -> x |> normalize |> query_find_by_partial_tag end)
      |> Enum.map(&Dms42.Repo.all/1)
      |> Enum.flat_map(fn x -> x end)
      |> Enum.map(fn x -> to_search_result(x, 2) end)

    {query, acc ++ result}
  end

  @spec find_by_exact_comments({String.t(), list(Dms42.Models.Document.t())}) ::
          {String.t(), list(Dms42.Models.SearchResult.t())}
  defp find_by_exact_comments({query, acc}) when length(acc) >= @max_result, do: {query, acc}

  defp find_by_exact_comments({query, acc}) do
    result =
      from(d in Document,
        where: ilike(d.comments, ^"%#{query}%"),
        order_by: d.inserted_at,
        limit: @max_result,
        select: d
      )
      |> Dms42.Repo.all()
      |> Enum.map(fn x -> to_search_result(x, 3) end)

    {query, result ++ acc}
  end

  @spec find_by_exact_ocr({String.t(), list(Dms42.Models.Document.t())}) ::
          list(Dms42.Models.SearchResult.t())
  defp find_by_exact_ocr({query, acc}) when length(acc) >= @max_result, do: {query, acc}

  defp find_by_exact_ocr({query, acc}) do
    result =
      from(d in Document,
        left_join: o in DocumentOcr,
        on: d.document_id == o.document_id,
        or_where: ilike(o.ocr_normalized, ^"%#{query}%"),
        order_by: d.inserted_at,
        limit: @max_result,
        select: d
      )
      |> Dms42.Repo.all()
      |> Enum.map(fn x -> to_search_result(x, 4) end)

    {query, result ++ acc}
  end

  @spec find_by_partial_ocr({String.t(), list(Dms42.Models.Document.t())}) ::
          list(Dms42.Models.SearchResult.t())
  defp find_by_partial_ocr({query, acc}) when length(acc) >= @max_result, do: {query, acc}

  defp find_by_partial_ocr({query, acc}) do
    result =
      query
      |> query_find_by_partial_ocr
      |> Enum.map(fn x -> to_search_result(x, 5) end)

    {query, result ++ acc}
  end

  @spec query_find_by_exact_tag(String.t()) :: Ecto.Queryable.t()
  defp query_find_by_exact_tag(term) do
    from(d in Document,
      left_join: dt in DocumentTag,
      on: d.document_id == dt.document_id,
      left_join: t in Tag,
      on: t.tag_id == dt.tag_id,
      or_where: t.name_normalized == ^term,
      order_by: d.inserted_at,
      limit: @max_result,
      select: d
    )
  end

  @spec query_find_by_partial_tag(String.t()) :: Ecto.Queryable.t()
  defp query_find_by_partial_tag(term) do
    from(d in Document,
      left_join: dt in DocumentTag,
      on: d.document_id == dt.document_id,
      left_join: t in Tag,
      on: t.tag_id == dt.tag_id,
      or_where: ilike(t.name_normalized, ^"%#{term}%"),
      order_by: d.inserted_at,
      limit: @max_result,
      select: d
    )
  end

  @spec query_find_by_exact_ocr(String.t()) :: Ecto.Queryable.t()
  def query_find_by_exact_ocr(term) do
    from(d in Document,
      left_join: o in DocumentOcr,
      on: d.document_id == o.document_id,
      or_where: ilike(o.ocr_normalized, ^"%#{term}%"),
      order_by: d.inserted_at,
      limit: @max_result,
      select: d
    )
  end

  @spec query_find_by_partial_ocr(String.t()) :: Ecto.Queryable.t()
  def query_find_by_partial_ocr(query) do
    terms = query |> normalize |> String.split(" ")

    case terms do
      [_] ->
        []

      terms ->
        base_query =
          from(d in Document,
            left_join: o in DocumentOcr,
            on: d.document_id == o.document_id
          )

        terms
        |> Enum.reduce(base_query, fn x, acc ->
          acc |> where([d, o], ilike(o.ocr_normalized, ^"%#{x}%"))
        end)
        |> order_by([d, o], d.inserted_at)
        |> limit([d, o], @max_result)
        |> select([d, o], d)
        |> Dms42.Repo.all()
    end
  end

  @spec to_search_result(Dms42.Models.Document.t(), integer) :: Dms42.Models.SearchResult.t()
  defp to_search_result(%Document{:document_id => did} = document, ranking) do
    %SearchResult{document_id: did, document: document, ranking: ranking}
  end
end

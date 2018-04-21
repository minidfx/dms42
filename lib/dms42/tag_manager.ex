defmodule Dms42.TagManager do
  import Ecto.Query, only: [from: 2]

  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.TransactionHelper
  alias Dms42.DocumentsFinder

  @doc """
    Add or update tags on a document.
  """
  @spec add_or_update!(document_id :: binary, tag_name :: String.t()) :: no_return()
  def add_or_update!(document_id, tag_name) when is_binary(document_id) do
    Ecto.Multi.new() |> add_or_update(document_id, tag_name)
                     |> TransactionHelper.commit!
  end

  @doc """
    Add or update tags on a document using a transaction.
  """
  @spec add_or_update(Ecto.Multi.t(), document_id :: binary, tag_name :: String.t()) :: Ecto.Multi.t()
  def add_or_update(transaction, document_id, tag_name) when is_binary(document_id) do
    tag_name_normalized  = tag_name |> DocumentsFinder.normalize
    case Tag |> Dms42.Repo.get_by(name_normalized: tag_name_normalized) do
      nil ->
        tag_id  = Ecto.UUID.bingenerate()
        transaction |> Ecto.Multi.insert_or_update("add_tag_#{tag_name_normalized}",
                                                   Tag.changeset(%Tag{},
                                                                 %{name: tag_name,
                                                                   name_normalized: tag_name_normalized,
                                                                   tag_id: tag_id}))
                    |> Ecto.Multi.insert_or_update("add_document_tag_#{tag_name_normalized}",
                                                   DocumentTag.changeset(%DocumentTag{},
                                                                         %{document_id: document_id,
                                                                           tag_id: tag_id}))
      %{tag_id: tid} -> transaction |> Ecto.Multi.insert_or_update("add_document_tag_#{tag_name_normalized}",
                                                                   DocumentTag.changeset(%DocumentTag{},
                                                                                         %{document_id: document_id,
                                                                                           tag_id: tid}))
    end
  end

  @doc """
    Removes the tag passing the given id from the document using a transaction.
  """
  @spec remove(Ecto.Multi.t(), document_id :: binary, tag_name :: String.t()) :: Ecto.Multi.t()
  def remove(transaction, document_id, tag_name) when is_binary(document_id) and is_bitstring(tag_name) do
    tag_name_normalized = tag_name |> DocumentsFinder.normalize
    case Dms42.Repo.get_by(Tag, name_normalized: tag_name_normalized) do
      nil -> transaction
      tag -> transaction |> remove(document_id, tag)
    end
  end

  @doc """
    Removes the tag from the document using a transaction.
  """
  @spec remove(Ecto.Multi.t(), document_id :: binary, tag :: Tag) :: Ecto.Multi.t()
  def remove(transaction, document_id, %Tag{:tag_id => tid, :name => t_name} = tag) when is_binary(document_id) and is_map(tag) do
    transaction |> Ecto.Multi.delete_all("tag_#{t_name}", (from DocumentTag, where: [document_id: ^document_id, tag_id: ^tid]))
                |> clean_tag(tag)
  end

  @spec remove!(document_id :: binary, tag_name :: String.t()) :: no_return()
  def remove!(document_id, tag_name) when is_binary(document_id) do
    Ecto.Multi.new() |> remove(document_id, tag_name)
                     |> TransactionHelper.commit!
  end

  @spec get_tags(document_id :: binary) :: list(Tag)
  def get_tags(document_id) when is_binary(document_id) do
    from( dt in DocumentTag,
          join: t in Tag,
          on: [tag_id: dt.tag_id],
          where: [document_id: ^document_id],
          select: t)
    |> Dms42.Repo.all
  end

  @spec clean_document_tags(Ecto.Multi.t(), document_id :: binary) :: Ecto.Multi.t()
  def clean_document_tags(transaction, document_id) when is_binary(document_id) do
    # NOTE: Use the reduce function to passthru the transaction to every requests but it's not a reduction!
    get_tags(document_id) |> Enum.reduce(transaction, fn (tag, t) -> remove(t, document_id, tag) end)
  end

  @spec clean_tag(Ecto.Multi.t(), tag :: Tag) :: Ecto.Multi.t()
  defp clean_tag(transaction, %Tag{:tag_id => tag_id} = tag) do
    result = (from dt in DocumentTag, where: dt.tag_id == ^tag_id, select: count(dt.id)) |> Dms42.Repo.all
    case result do
      [0] -> transaction |> Ecto.Multi.delete("clean_tag_#{tag_id}", tag)
      _ -> transaction
    end
  end
end

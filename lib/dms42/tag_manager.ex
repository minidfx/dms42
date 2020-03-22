defmodule Dms42.TagManager do
  import Ecto.Query, only: [from: 2]

  alias Dms42.Models.DocumentTag
  alias Dms42.Models.Tag
  alias Dms42.TransactionHelper
  alias Dms42.DocumentsFinder

  @doc """
    Updates the existing tag and thrown an error if the update failed.
  """
  def update!(old_tag_name, new_tag_name) do
    Ecto.Multi.new()
    |> update(old_tag_name, new_tag_name)
    |> TransactionHelper.commit!()
  end

  @doc """
    Updates the existing tag.
  """
  def update(transaction, old_tag_name, new_tag_name) do
    new_tag_name_normalized = new_tag_name |> DocumentsFinder.normalize()
    new_tag = Tag |> Dms42.Repo.get_by(name_normalized: new_tag_name_normalized)
    existing_tag = Tag |> Dms42.Repo.get_by(name_normalized: old_tag_name)

    case {new_tag, existing_tag} do
      {_, nil} ->
        {:error, "The tag with given name #{old_tag_name} to rename is not found."}

      {nil, tag} ->
        transaction
        |> Ecto.Multi.update(
          "add_tag_#{new_tag_name_normalized}",
          Tag.changeset(
            tag,
            %{name: new_tag_name, name_normalized: new_tag_name_normalized}
          )
        )

      {_, _} ->
        {:error, "A tag with the given name #{new_tag_name} already exist."}
    end
  end

  @doc """
    Add or update tags on a document.
  """
  def add_or_update!(document_id, tag_name) when is_binary(document_id) do
    Ecto.Multi.new()
    |> add_or_update(document_id, tag_name)
    |> TransactionHelper.commit!()
  end

  @doc """
    Add or update tags on a document using a transaction.
  """
  def add_or_update(transaction, document_id, tag_name) when is_binary(document_id) do
    tag_name_normalized = tag_name |> DocumentsFinder.normalize()

    case Tag |> Dms42.Repo.get_by(name_normalized: tag_name_normalized) do
      nil ->
        tag_id = Ecto.UUID.bingenerate()

        transaction
        |> Ecto.Multi.insert_or_update(
          "add_tag_#{tag_name_normalized}",
          Tag.changeset(
            %Tag{},
            %{name: tag_name, name_normalized: tag_name_normalized, tag_id: tag_id}
          )
        )
        |> Ecto.Multi.insert_or_update(
          "add_document_tag_#{tag_name_normalized}",
          DocumentTag.changeset(
            %DocumentTag{},
            %{document_id: document_id, tag_id: tag_id}
          )
        )

      %{tag_id: tid} ->
        transaction
        |> Ecto.Multi.insert_or_update(
          "add_document_tag_#{tag_name_normalized}",
          DocumentTag.changeset(
            %DocumentTag{},
            %{document_id: document_id, tag_id: tid}
          )
        )
    end
  end

  @doc """
    Removes the tag passing the given id from the document using a transaction.
  """
  def remove(transaction, document_id, tag_name) when is_binary(document_id) and is_bitstring(tag_name) do
    tag_name_normalized = tag_name |> DocumentsFinder.normalize()

    case Dms42.Repo.get_by(Tag, name_normalized: tag_name_normalized) do
      nil -> transaction
      tag -> transaction |> remove(document_id, tag)
    end
  end

  @doc """
    Removes the tag from the document using a transaction.
  """
  def remove(transaction, document_id, %Tag{:tag_id => tid, :name => t_name} = tag) when is_binary(document_id) and is_map(tag) do
    transaction
    |> Ecto.Multi.delete_all("tag_#{t_name}", from(DocumentTag, where: [document_id: ^document_id, tag_id: ^tid]))
    |> clean_tag(tag)
  end

  def remove!(document_id, tag_name) when is_binary(document_id) do
    Ecto.Multi.new()
    |> remove(document_id, tag_name)
    |> TransactionHelper.commit!()
  end

  def get_tags(document_id) when is_binary(document_id) do
    from(dt in DocumentTag,
      join: t in Tag,
      on: [tag_id: dt.tag_id],
      where: [document_id: ^document_id],
      select: t
    )
    |> Dms42.Repo.all()
  end

  @doc """
    Returns all tags saved.
  """
  def get_tags() do
    Tag |> Dms42.Repo.all()
  end

  def clean_document_tags(transaction, document_id) when is_binary(document_id) do
    # NOTE: Use the reduce function to passthru the transaction to every requests but it's not a reduction!
    get_tags(document_id) |> Enum.reduce(transaction, fn tag, t -> remove(t, document_id, tag) end)
  end

  defp clean_tag(transaction, %Tag{:tag_id => tag_id} = tag) do
    result = from(dt in DocumentTag, where: dt.tag_id == ^tag_id, select: count(dt.id)) |> Dms42.Repo.all()

    case result do
      [0] -> transaction |> Ecto.Multi.delete("clean_tag_#{tag_id}", tag)
      _ -> transaction
    end
  end
end

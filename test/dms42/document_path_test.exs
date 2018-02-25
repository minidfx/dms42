defmodule Dms42Web.DocumentPathTest do
  use ExUnit.Case, async: false

  import ExMock

  alias Dms42.DocumentPath
  alias Dms42.Models.Document

  test "get the document absolute path passing a Document struct" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    {:ok, inserted_at, _} = DateTime.from_iso8601("2015-01-23T23:50:07Z")
    result = DocumentPath.document_path!(%Document{document_id: uuid, inserted_at: inserted_at})
    current_folder = System.cwd()
    expected_result = "#{current_folder}/documents/2015/1/23/#{uuid}"
    assert expected_result == result
  end

  test "get the document absolute path passing a uuid" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    %{:year => year, :month => month, :day => day} =  DateTime.utc_now()
    result = DocumentPath.document_path!(uuid)
    current_folder = System.cwd()
    expected_result = "#{current_folder}/documents/#{year}/#{month}/#{day}/#{uuid}"
    assert expected_result == result
  end

  test "get the small thumbnail absolute path passing a uuid" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    %{:year => year, :month => month, :day => day} =  DateTime.utc_now()
    result = DocumentPath.small_thumbnail_path!(uuid)
    current_folder = System.cwd()
    expected_result = "#{current_folder}/thumbnails/#{year}/#{month}/#{day}/#{uuid}/small.png"
    assert expected_result == result
  end

  test "get the small thumbnail absolute path passing a Document struct" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    {:ok, inserted_at, _} = DateTime.from_iso8601("2015-01-23T23:50:07Z")
    result = DocumentPath.small_thumbnail_path!(%Document{document_id: uuid, inserted_at: inserted_at})
    current_folder = System.cwd()
    expected_result = "#{current_folder}/thumbnails/2015/1/23/#{uuid}/small.png"
    assert expected_result == result
  end

  test "get the big thumbnail absolute paths passing a Document struct" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    {:ok, inserted_at, _} = DateTime.from_iso8601("2015-01-23T23:50:07Z")
    current_folder = System.cwd()
    expected_result = "#{current_folder}/thumbnails/2015/1/23/#{uuid}"
    with_mock File,
      [ls!: fn(path) ->
            assert expected_result == path
            []
           end] do
        DocumentPath.big_thumbnail_paths!(%Document{document_id: uuid, inserted_at: inserted_at})
    end
  end

  test "get the big thumbnail absolute paths passing a uuid" do
    document_id = Ecto.UUID.bingenerate()
    {:ok, uuid} = Ecto.UUID.load(document_id)
    %{:year => year, :month => month, :day => day} =  DateTime.utc_now()
    current_folder = System.cwd()
    expected_path_result = "#{current_folder}/thumbnails/#{year}/#{month}/#{day}/#{uuid}"
    with_mock File,
      [ls!: fn(path) ->
            assert expected_path_result == path
            ["#{expected_path_result}/titi.png",
             "#{expected_path_result}/big-0.png",
             "#{expected_path_result}/big-1.png",
             "#{expected_path_result}/big-99.png",
             "#{expected_path_result}/big-10.png",
             "#{expected_path_result}/big-2.png",
             "#{expected_path_result}/toto.ext"]
           end] do
        expected_result = ["#{expected_path_result}/big-0.png",
                           "#{expected_path_result}/big-1.png",
                           "#{expected_path_result}/big-2.png",
                           "#{expected_path_result}/big-10.png",
                           "#{expected_path_result}/big-99.png"]
        result = DocumentPath.big_thumbnail_paths!(uuid)
        assert expected_result == result
    end
  end

  test "get the big thumbnail relative path passing a uuid" do
    expected_result = "thumbnails"
    result = DocumentPath.thumbnail_folder_relative_path!()
    assert expected_result == result
  end

  test "get the document relative path passing a uuid" do
    result = DocumentPath.document_folder_relative_path!()
    expected_result = "documents"
    assert expected_result == result
  end
end

defmodule Incense.Storage.ObjectTest do
  use ExUnit.Case, async: true

  alias Incense.Storage.Object

  @moduletag :storage

  setup do
    bucket = "incense-test"
    doge_file = {:file, Path.expand("../../support/doge_the_dog.jpg", __DIR__)}

    {:ok, bucket: bucket, doge_file: doge_file}
  end

  test "doge_file", %{doge_file: doge_file} do
    {_, path} = doge_file
    assert File.exists?(path)
  end

  @tag :external
  test "simple_upload", %{bucket: bucket, doge_file: doge_file} do
    assert :ok = Object.simple_upload(bucket, "2016/10/05/doge.jpg", doge_file, "image/jpeg")
  end

  @tag :external
  test "delete", %{bucket: bucket, doge_file: doge_file} do
    assert :ok = Object.simple_upload(bucket, "2032/10/10/doge.jpg", doge_file, "image/jpeg")
    assert :ok = Object.delete(bucket, "2032/10/10/doge.jpg")
  end

  @tag :external
  test "batch_delete", %{bucket: bucket, doge_file: doge_file} do
    names =
      for i <- 1..2 do
        name = "2064/10/10/doge#{i}.jpg"
        assert :ok = Object.simple_upload(bucket, name, doge_file, "image/jpeg")

        name
      end

    assert :ok = Object.batch_delete(bucket, names)
  end

  @tag :external
  test "massive batch_delete", %{bucket: bucket} do
    names =
      for i <- 1..1000 do
        "2064/10/10/massive_doge#{i}.jpg"
      end

    assert :ok = Object.batch_delete(bucket, names)
  end
end

defmodule Incense.Storage.Client do
  use Incense.Client, scope: "https://www.googleapis.com/auth/devstorage.read_write"

  defp process_url(url) do
    "https://www.googleapis.com/storage/v1" <> url
  end
end

defmodule Incense.Storage.UploadClient do
  use Incense.Client, scope: "https://www.googleapis.com/auth/devstorage.read_write"

  defp process_url(url) do
    "https://www.googleapis.com/upload/storage/v1" <> url
  end
end

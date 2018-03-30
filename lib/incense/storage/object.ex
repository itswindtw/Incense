defmodule Incense.Storage.Object do
  use Incense.Backoff

  alias Incense.Storage.{UploadClient, Client}

  def simple_upload(bucket, name, content, content_type, predefined_acl \\ "projectPrivate") do
    query_str = URI.encode_query(name: name, predefinedAcl: predefined_acl)
    upload_url = "/b/#{bucket}/o?uploadType=media&#{query_str}"

    Incense.Backoff.retry do
      case UploadClient.post(upload_url, content, [{"Content-Type", content_type}]) do
        {:ok, %HTTPoison.Response{status_code: 200}} -> :ok
        {:ok, resp} -> {:error, resp.status_code}
        result -> result
      end
    end
  end

  def delete(bucket, name) do
    object_url = "/b/#{bucket}/o/#{URI.encode_www_form(name)}"

    case Client.delete(object_url) do
      {:ok, resp} ->
        case resp.status_code do
          204 -> :ok
          404 -> :ok
          _ -> {:error, resp.status_code}
        end

      result ->
        result
    end
  end

  def batch_delete(bucket, names) do
    {:ok, conn_ref} = :hackney.connect("https://www.googleapis.com", [{:recv_timeout, 30000}])

    for names <- Enum.chunk_every(names, 100) do
      Incense.Backoff.retry do
        do_batch_delete(conn_ref, bucket, names)
      end
    end

    :hackney.close(conn_ref)

    :ok
  end

  defp do_batch_delete(conn_ref, bucket, names) do
    boundary = :hackney_multipart.boundary()

    headers = [{"Content-Type", "multipart/mixed; boundary=\"#{boundary}\""}]
    headers = Client.process_request_headers(headers)

    mixed_body =
      for name <- names do
        """
        Content-Type: application/http\r
        \r
        DELETE /storage/v1/b/#{bucket}/o/#{URI.encode_www_form(name)} HTTP/1.1\r
        content-length: 0\r
        """
      end
      |> Enum.join("--" <> boundary <> "\r\n")

    body = "\r\n--" <> boundary <> "\r\n" <> mixed_body <> "--" <> boundary <> "--"

    {:ok, _status, _, conn_ref} =
      :hackney.send_request(conn_ref, {:post, "/batch/storage/v1", headers, body})

    :hackney.skip_body(conn_ref)
  end
end

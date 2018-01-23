defmodule Incense.Client do
  defmacro __using__(scope: scope) do
    quote do
      use HTTPoison.Base

      def process_request_headers(headers) do
        {:ok, token} = Incense.Token.get(unquote(scope))

        Enum.into(headers, [{"Authorization", "Bearer #{token}"}])
      end

      defp process_response_body(""), do: nil

      defp process_response_body(body) do
        case Poison.decode(body) do
          {:ok, result} -> result
          {:error, _} -> body
        end
      end
    end
  end
end

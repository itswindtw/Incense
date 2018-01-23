defmodule Incense.Backoff do
  @retry_unit Application.get_env(:incense, Incense.Backoff)[:retry_unit]

  defmacro __using__(opts) do
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_unit = Keyword.get(opts, :retry_unit, @retry_unit)

    quote do
      @max_retries unquote(max_retries)
      @retry_unit unquote(retry_unit)
    end
  end

  defmacro retry(do: block) do
    do_retry(block)
  end

  defp do_retry(block) do
    quote do
      f = unquote(attempt(block))

      Enum.reduce_while(1..@max_retries, nil, fn i, last ->
        case f.() do
          {:cont, _} = result ->
            sleep_ms = ((:math.pow(2, i) + :rand.uniform()) * @retry_unit) |> round
            if sleep_ms > 0, do: :timer.sleep(sleep_ms)

            result

          result ->
            result
        end
      end)
      |> case do
        {:exception, e} -> raise e
        result -> result
      end
    end
  end

  defp attempt(block) do
    quote do
      fn ->
        try do
          case unquote(block) do
            :error -> {:cont, :error}
            {:error, _} = x -> {:cont, x}
            result -> {:halt, result}
          end
        rescue
          e in RuntimeError -> {:cont, {:exception, e}}
        end
      end
    end
  end
end

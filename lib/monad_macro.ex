defmodule MonadMacro do
  import Kernel, except: [|>: 2]

  defmacro __using__(_params) do
    quote do
      import MonadMacro
      import Kernel, except: [|>: 2]
    end
  end

  defp original_implementation(left, right) do
    [{h, _} | t] = Macro.unpipe({:|>, [], [left, right]})

    fun = fn {x, pos}, acc ->
      Macro.pipe(acc, x, pos)
    end

    :lists.foldl(fun, h, t)
  end

  defp filter(left, op) do
    quote do
      case unquote(left) do
        e = {:error, _} -> e
        _               -> unquote(op)
      end
    end
  end

  defp extractor(left) do
    quote do
      case unquote(left) do
        {:ok, v}  -> v
        v         -> v
      end
    end
  end

  defp unit(left, result) do
    quote do
      case {unquote(result), unquote(left)} do
        {e = {:error, _}, _}  -> e
        {o = {:ok, _}, _}     -> o
        {val, :monad}         -> {:ok, val}
        {val, _}              -> val
      end
    end
  end

  defmacro left |> right do
    extracted = extractor(left)
    operation = original_implementation(extracted, right)
    result = filter(left, operation)
    unit(left, result)
  end
end

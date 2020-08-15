defmodule MonadMacro do
  @moduledoc """
  This module implements a wrapper version of the pipe operator.

  The implementation consider a "monad" the tuple {:ok, value} and {:error, reason}, having that
  this is a common pattern.
  If the input value is in the form of {:ok, value} | {:error, reason}, the pipe operator performs
  these checks:

  1. If the value is an error, stops the elaboration, returning the {:error, reason};
  2. If the value is {:ok, value}, continues the elaboration passing value:
    a. If the elaboration returns a normal value, wraps the result in {:ok, result};
    b. If the value is of type {:ok, result} | {:error, reason}, returns the result.
  3. If the value is a normal value, the macro relies on the official implementation.
     In this case, it will not wrap the result value (normal behavior).
  """

  import Kernel, except: [|>: 2]

  defmacro __using__(_params) do
    quote do
      import MonadMacro
      import Kernel, except: [|>: 2]
    end
  end

  @doc """
  The original implementation of the macro.
  This macro relies on this implementation in every case, passing different codes in input.
  """
  defp original_implementation(left, right) do
    [{h, _} | t] = Macro.unpipe({:|>, [], [left, right]})

    fun = fn {x, pos}, acc ->
      Macro.pipe(acc, x, pos)
    end

    :lists.foldl(fun, h, t)
  end

  @doc """
  This function filters the different values of left.
  If left is an error, stops the operation and return the error, otherwise performs the operation op.
  This function is necessary to filter away any error before performing the operation,
  this way the other function can focus on correct values.
  """
  defp filter(left, op) do
    quote do
      case unquote(left) do
        e = {:error, _} -> e
        _               -> unquote(op)
      end
    end
  end

  @doc """
  This function unwrap the {:ok, value} "monad", returning the value inside it.
  If left is a simple value, returns the value itself.
  The error here is not considered, because it was filtered away in the filter function.
  """
  defp extractor(left) do
    quote do
      case unquote(left) do
        {:ok, v}  -> v
        v         -> v
      end
    end
  end

  @doc """
  This function wraps the result of the operation in a "monad" in the form of {:ok, result} if necessary.
  In particular, if the input value was of type {:ok, value} | {:error, reason} and the result is not,
  it wraps the result to retorn a monad
  If the input value was a normal value, this function simply returns the result, that could be of type
  {:ok, result} | {:error, reason}, depending entirely on the "right" function.
  """
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

  @doc """
  This macro groups all the function together, in order to perform the following:
  1. Filter the error value, returning it if it's the case;
  2. Extract the value from the {:ok, value} type, if necessary;
  3. Wrap the result if necessary, with the unit function.
  """
  defmacro left |> right do
    extracted = extractor(left)
    operation = original_implementation(extracted, right)
    result = filter(left, operation)
    unit(left, result)
  end
end

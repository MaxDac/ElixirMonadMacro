defmodule OkErrorPipeTest do
  use ExUnit.Case
  use OkErrorPipe
  doctest OkErrorPipe

  def monad_map(ls) do
    result = Enum.map(ls, fn x -> x * 10 end)
    {:ok, result}
  end

  def error_monad(_, reason) do
    {:error, reason}
  end

  test "Works normally with normal values" do
    ls = [1, 2, 3]
    result = ls |> Enum.map(fn x -> x * 10 end)
    assert(result == [10, 20, 30])
  end

  test "Works normally with normal values when returning a monad" do
    ls = {:ok, [1, 2, 3]}
    result = ls |> monad_map()
    assert(result == {:ok, [10, 20, 30]})
  end

  test "Correctly binds a monad" do
    ls = {:ok, [1, 2, 3]}
    result = ls |> monad_map()
    assert(result == {:ok, [10, 20, 30]})
  end

  test "Returns an error when a normal value is in input" do
    ls = [1, 2, 3]
    result = ls |> error_monad(:some_reason)
    assert result == {:error, :some_reason}
  end

  test "Returns a monad when the function returns a normal value" do
    ls = {:ok, [1, 2, 3]}
    result = ls |> Enum.map(fn x -> x * 10 end)
    assert result == {:ok, [10, 20, 30]}
  end

  test "Correctly reports the value, encapsulated only in one monad" do
    ls = [1, 2, 3]

    result =
      ls
      |> monad_map()
      |> monad_map()

    assert(result == {:ok, [100, 200, 300]})
  end

  test "Returns error and does not continue" do
    ls = [1, 2, 3]

    result =
      ls
      |> error_monad(:some_reason)
      |> monad_map()

    assert(result == {:error, :some_reason})
  end

  test "Returns the correct error (the first)" do
    ls = [1, 2, 3]

    result =
      ls
      |> error_monad(:some_reason)
      |> error_monad(:some_other_reason)

    assert(result == {:error, :some_reason})
  end

  test "With monadic input: Correctly reports the value, encapsulated only in one monad" do
    ls = {:ok, [1, 2, 3]}

    result =
      ls
      |> monad_map()
      |> monad_map()

    assert(result == {:ok, [100, 200, 300]})
  end

  test "With monadic input: Returns error and does not continue" do
    ls = {:ok, [1, 2, 3]}

    result =
      ls
      |> error_monad(:some_reason)
      |> monad_map()

    assert(result == {:error, :some_reason})
  end

  test "With monadic input: Returns the correct error (the first)" do
    ls = {:ok, [1, 2, 3]}

    result =
      ls
      |> error_monad(:some_reason)
      |> error_monad(:some_other_reason)

    assert(result == {:error, :some_reason})
  end
end

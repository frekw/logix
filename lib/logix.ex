defmodule Logix do
  defmodule DSL do
    defmacro __using__(env) do
      quote do
        import Kernel, except: [{:==, 2}]
        import Logix
        import Logix.DSL, only: [goal: 1]
      end
    end

    defmacro goal(do: body) do
      quote do
        fn sc ->
          fn ->
            unquote(body).(sc)
          end
        end
      end
    end
  end

  import Kernel, except: [{:==, 2}]

  def new, do: {%{}, 0}

  def env(pairs) do
    s =
      pairs
      |> Stream.chunk_every(2)
      |> Stream.map(fn [k, v] -> {k, v} end)
      |> Enum.into(%{})

    {s, 0}
  end

  def var(v), do: {:var, v}

  def var?({:var, v}) when is_integer(v), do: true
  def var?(_), do: false

  def walk(v, s) do
    case var?(v) and Map.has_key?(s, v) do
      true -> walk(Map.get(s, v), s)
      false -> v
    end
  end

  def zero, do: []
  def unit(sc), do: [sc | zero()]

  def unify(u, v, s) do
    u = walk(u, s)
    v = walk(v, s)

    cond do
      var?(u) and var?(v) and Kernel.==(u, v) ->
        s

      var?(u) ->
        Map.put(s, u, v)

      var?(v) ->
        Map.put(s, v, u)

      is_list(v) && is_list(u) ->
        s = unify(head(u), head(v), s)
        s && unify(tail(u), tail(v), s)

      Kernel.==(u, v) ->
        s

      true ->
        nil
    end
  end

  def u == v do
    fn {s, c} ->
      s = unify(u, v, s)

      case s do
        nil -> zero()
        s -> unit({s, c})
      end
    end
  end

  def callfresh(f) do
    fn {s, c} ->
      f.(var(c)).({s, c + 1})
    end
  end

  # or
  def disj(g1, g2) do
    fn sc ->
      mplus(g1.(sc), g2.(sc))
    end
  end

  # and
  def conj(g1, g2) do
    fn sc ->
      bind(g1.(sc), g2)
    end
  end

  def take(_, 0), do: []

  def take(s, n) do
    case pull(s) do
      [] -> []
      [h | t] -> [h | take(t, n - 1)]
    end
  end

  def take_all(s) do
    case pull(s) do
      [] -> []
      [h | t] -> [h | take_all(t)]
    end
  end

  def callgoal(g) do
    g.(new())
  end

  defp pull(s) do
    case is_function(s) do
      true -> pull(s.())
      false -> s
    end
  end

  defp mplus(s1, s2) when is_function(s1) do
    fn -> mplus(s2, s1.()) end
  end

  defp mplus(s1, s2) do
    case s1 do
      [] -> s2
      [h | t] -> [h | mplus(t, s2)]
    end
  end

  defp bind(s, g) when is_function(s) do
    fn -> bind(s.(), g) end
  end

  defp bind(s, g) do
    case s do
      [] -> zero()
      [h | t] -> mplus(g.(h), bind(t, g))
    end
  end

  defp head([h | _]), do: h
  defp head(_), do: nil

  defp tail([_ | t]), do: t
  defp tail([]), do: nil
end

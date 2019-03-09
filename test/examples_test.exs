defmodule LogixExamples do
  use ExUnit.Case
  use Logix.DSL

  def fives(x) do
    disj(
      x == 5,
      goal do
        fives(x)
      end
    )
  end

  test "it returns fives" do
    v = var(0)
    res = take(callgoal(callfresh(&fives/1)), 2)

    assert res == [
             {%{v => 5}, 1},
             {%{v => 5}, 1}
           ]
  end

  test "disj" do
    res =
      take_all(
        callgoal(
          callfresh(fn q ->
            disj(
              q == 5,
              q == q
            )
          end)
        )
      )

    assert res == [
             {%{var(0) => 5}, 1},
             {%{}, 1}
           ]
  end

  test "conj" do
    res =
      take_all(
        callgoal(
          callfresh(fn q ->
            conj(
              q == 5,
              q == q
            )
          end)
        )
      )

    assert res == [
             {%{var(0) => 5}, 1}
           ]
  end
end

defmodule Tests.Delta do
  use Delta.Support.Case, async: true

  doctest Delta,
    only: [
      compact: 1,
      concat: 2,
      push: 2,
      size: 1,
      slice: 3,
      slice_max: 3,
      split: 3
    ]

  # NOTE: {compose, transform, invert, diff} tests are in their
  # dedicated test suites under delta/

  describe ".slice/3" do
    test "slice across" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice(delta, 1, 7) == [
               %{"insert" => "BC"},
               %{"insert" => "012", "attributes" => %{bold: true}},
               %{"insert" => "DE"}
             ]
    end

    test "slice boundaries" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice(delta, 3, 3) == [
               %{"insert" => "012", "attributes" => %{bold: true}}
             ]
    end

    test "slice middle" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice(delta, 4, 1) == [
               %{"insert" => "1", "attributes" => %{bold: true}}
             ]
    end

    test "slice normal emoji" do
      delta = [%{"insert" => "01🙋45"}]
      assert Delta.slice(delta, 1, 4) == [%{"insert" => "1🙋45"}]
    end

    test "slice emoji with zero width joiner" do
      delta = [%{"insert" => "01🙋‍♂️78"}]
      assert Delta.slice(delta, 1, 7) == [%{"insert" => "1🙋‍♂️78"}]
    end

    test "slice emoji with joiner and modifer" do
      delta = [%{"insert" => "01🙋🏽‍♂️90"}]
      assert Delta.slice(delta, 1, 9) == [%{"insert" => "1🙋🏽‍♂️90"}]
    end

    test "slice with 0 index" do
      delta = [Op.insert("12")]
      assert Delta.slice(delta, 0, 1) == [%{"insert" => "1"}]
    end

    test "slice insert object with 0 index" do
      delta = [Op.insert(%{"id" => "1"}), Op.insert(%{"id" => "2"})]
      assert Delta.slice(delta, 0, 1) == [%{"insert" => %{"id" => "1"}}]
    end
  end

  describe ".slice_max/3" do
    test "slice across" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice_max(delta, 1, 7) == [
               %{"insert" => "BC"},
               %{"insert" => "012", "attributes" => %{bold: true}},
               %{"insert" => "DE"}
             ]
    end

    test "slice boundaries" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice_max(delta, 3, 3) == [
               %{"insert" => "012", "attributes" => %{bold: true}}
             ]
    end

    test "slice middle" do
      delta = [
        %{"insert" => "ABC"},
        %{"insert" => "012", "attributes" => %{bold: true}},
        %{"insert" => "DEF"}
      ]

      assert Delta.slice_max(delta, 4, 1) == [
               %{"insert" => "1", "attributes" => %{bold: true}}
             ]
    end

    test "slice normal emoji" do
      delta = [%{"insert" => "01🙋45"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1🙋45"}]
    end

    test "slice emoji with zero width joiner" do
      delta = [%{"insert" => "01🙋‍♂️78"}]
      assert Delta.slice_max(delta, 1, 7) == [%{"insert" => "1🙋‍♂️78"}]
    end

    test "slice emoji with joiner and modifer" do
      delta = [%{"insert" => "01🙋🏽‍♂️90"}]
      assert Delta.slice_max(delta, 1, 9) == [%{"insert" => "1🙋🏽‍♂️90"}]
    end

    test "slice with 0 index" do
      delta = [Op.insert("12")]
      assert Delta.slice_max(delta, 0, 1) == [%{"insert" => "1"}]
    end

    test "slice insert object with 0 index" do
      delta = [Op.insert(%{"id" => "1"}), Op.insert(%{"id" => "2"})]
      assert Delta.slice_max(delta, 0, 1) == [%{"insert" => %{"id" => "1"}}]
    end

    test "slice emoji: codepoint + variation selector" do
      # "01☹️345"
      delta = [%{"insert" => "01\u2639\uFE0F345"}]
      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1☹️"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1☹️3"}]
    end

    test "slice emoji: codepoint + skin tone modifier" do
      # "01🤵🏽345"
      delta = [%{"insert" => "01\u{1F935}\u{1F3FD}345"}]
      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1🤵🏽"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1🤵🏽3"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1🤵🏽34"}]
      assert Delta.slice_max(delta, 1, 5) == [%{"insert" => "1🤵🏽345"}]
    end

    test "slice emoji: codepoint + ZWJ + codepoint" do
      # "01👨‍🏭345"
      delta = [%{"insert" => "01\u{1F468}\u200D\u{1F3ED}345"}]
      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1👨‍🏭"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1👨‍🏭3"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1👨‍🏭34"}]
      assert Delta.slice_max(delta, 1, 5) == [%{"insert" => "1👨‍🏭345"}]
      assert Delta.slice_max(delta, 1, 6) == [%{"insert" => "1👨‍🏭345"}]
    end

    test "slice emoji: flags" do
      # "01🇦🇺345"
      delta = [%{"insert" => "01\u{1F1E6}\u{1F1FA}345"}]
      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1🇦🇺"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1🇦🇺3"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1🇦🇺34"}]
      assert Delta.slice_max(delta, 1, 5) == [%{"insert" => "1🇦🇺345"}]
    end

    test "slice emoji: tag sequence" do
      # "01🏴󠁧󠁢󠁳󠁣󠁴󠁿345"
      delta = [
        %{"insert" => "01\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}345"}
      ]

      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1🏴󠁧󠁢󠁳󠁣󠁴󠁿"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1🏴󠁧󠁢󠁳󠁣󠁴󠁿3"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1🏴󠁧󠁢󠁳󠁣󠁴󠁿34"}]
      assert Delta.slice_max(delta, 1, 5) == [%{"insert" => "1🏴󠁧󠁢󠁳󠁣󠁴󠁿345"}]
      assert Delta.slice_max(delta, 1, 6) == [%{"insert" => "1🏴󠁧󠁢󠁳󠁣󠁴󠁿345"}]
    end

    test "slice complex emoji" do
      # "01🚵🏻‍♀️345"
      delta = [%{"insert" => "01\u{1F6B5}\u{1F3FB}\u{200D}\u{2640}\u{FE0F}345"}]
      assert Delta.slice_max(delta, 1, 2) == [%{"insert" => "1🚵🏻‍♀️"}]
      assert Delta.slice_max(delta, 1, 3) == [%{"insert" => "1🚵🏻‍♀️3"}]
      assert Delta.slice_max(delta, 1, 4) == [%{"insert" => "1🚵🏻‍♀️34"}]
      assert Delta.slice_max(delta, 1, 5) == [%{"insert" => "1🚵🏻‍♀️345"}]
      assert Delta.slice_max(delta, 1, 6) == [%{"insert" => "1🚵🏻‍♀️345"}]
      assert Delta.slice_max(delta, 1, 7) == [%{"insert" => "1🚵🏻‍♀️345"}]

      assert Delta.slice_max(delta, 1, 8) == [
               %{"insert" => "1\u{1F6B5}\u{1F3FB}\u{200D}\u{2640}\u{FE0F}345"}
             ]
    end
  end

  describe ".split/3" do
    test "split at op boundary" do
      delta = [
        Op.insert("hello"),
        Op.insert(%{"code-embed" => []}),
        Op.insert("world")
      ]

      # this splitter should split the delta immediately before the first embed
      assert Delta.split(delta, fn
               %{"insert" => text}, _ when is_binary(text) -> :cont
               _, _ -> 0
             end) ==
               {[Op.insert("hello")],
                [
                  Op.insert(%{"code-embed" => []}),
                  Op.insert("world")
                ]}
    end
  end

  describe ".push/2" do
    test "push merge" do
      delta =
        []
        |> Delta.push(Op.insert("Hello"))
        |> Delta.push(Op.insert(" World!"))

      assert(delta == [%{"insert" => "Hello World!"}])
    end

    test "push redundant" do
      delta =
        []
        |> Delta.push(Op.insert("Hello"))
        |> Delta.push(Op.retain(0))

      assert(delta == [%{"insert" => "Hello"}])
    end

    @tag skip: true
    test "insert after delete" do
      flunk("implement this")
    end
  end
end

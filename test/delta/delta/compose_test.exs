defmodule Tests.Delta.Compose do
  use Delta.Support.Case, async: false
  doctest Delta, only: [compose: 2, compose_all: 1]

  describe ".compose/2 (utf-16/32)" do
    test "take_partial with two 16-bit code units" do
      a = [Op.insert("Take the 💊💊")]
      b = [Op.retain(10)]

      assert [%{"insert" => "Take the 💊💊"}] == Delta.compose(a, b)
    end
  end

  describe ".compose/2 (basic)" do
    test "insert + insert" do
      a = [Op.insert("A")]
      b = [Op.insert("B")]
      expected = [Op.insert("BA")]

      assert Delta.compose(a, b) == expected
    end

    test "insert + insert (with attributes)" do
      a = [Op.insert("A", %{"bold" => true})]
      b = [Op.insert("B", %{"bold" => true})]
      expected = [Op.insert("BA", %{"bold" => true})]

      assert Delta.compose(a, b) == expected
    end

    test "insert + retain" do
      a = [Op.insert("A")]
      b = [Op.retain(1, %{"bold" => true, "color" => "red", "font" => nil})]
      expected = [Op.insert("A", %{"bold" => true, "color" => "red"})]

      assert Delta.compose(a, b) == expected
    end

    test "insert + delete" do
      a = [Op.insert("A")]
      b = [Op.delete(1)]
      expected = []

      assert Delta.compose(a, b) == expected
    end

    test "delete + insert" do
      a = [Op.delete(1)]
      b = [Op.insert("B")]
      expected = [Op.insert("B"), Op.delete(1)]

      assert Delta.compose(a, b) == expected
    end

    test "delete + retain" do
      a = [Op.delete(1)]
      b = [Op.retain(1, %{"bold" => true, "color" => "red"})]
      expected = [Op.delete(1), Op.retain(1, %{"bold" => true, "color" => "red"})]

      assert Delta.compose(a, b) == expected
    end

    test "delete + delete" do
      a = [Op.delete(1)]
      b = [Op.delete(1)]
      expected = [Op.delete(2)]

      assert Delta.compose(a, b) == expected
    end

    test "delete + delete different attributes" do
      a = [Op.delete(1, %{"foo" => true})]
      b = [Op.delete(1, %{"bar" => true})]
      expected = [Op.delete(1, %{"foo" => true}), Op.delete(1, %{"bar" => true})]

      assert Delta.compose(a, b) == expected
    end

    test "delete + delete same attributes" do
      a = [Op.delete(1, %{"foo" => true})]
      b = [Op.delete(1, %{"foo" => true})]
      expected = [Op.delete(2, %{"foo" => true})]

      assert Delta.compose(a, b) == expected
    end

    test "retain + insert" do
      a = [Op.retain(1, %{"color" => "blue"})]
      b = [Op.insert("B")]
      expected = [Op.insert("B"), Op.retain(1, %{"color" => "blue"})]

      assert Delta.compose(a, b) == expected
    end

    test "retain + retain (plain)" do
      a = b = [Op.retain(1)]
      assert Delta.compose(a, b) == []
    end

    test "retain + retain (with attributes)" do
      a = [Op.retain(1, %{"color" => "blue"})]
      b = [Op.retain(1, %{"bold" => true, "color" => "red", "font" => nil})]
      expected = [Op.retain(1, %{"bold" => true, "color" => "red", "font" => nil})]

      assert Delta.compose(a, b) == expected
    end

    test "retain + delete" do
      a = [Op.retain(1, %{"color" => "blue"})]
      b = [Op.delete(1)]
      expected = [Op.delete(1)]

      assert Delta.compose(a, b) == expected
    end

    test "insert in middle of text" do
      a = [Op.insert("Hello")]
      b = [Op.retain(3), Op.insert("X")]
      expected = [Op.insert("HelXlo")]

      assert Delta.compose(a, b) == expected
    end

    test "insert/delete ordering" do
      base = [Op.insert("Hello")]
      insert_first = [Op.retain(3), Op.insert("X"), Op.delete(1)]
      delete_first = [Op.retain(3), Op.delete(1), Op.insert("X")]
      expected = [Op.insert("HelXo")]

      assert Delta.compose(base, insert_first) == expected
      assert Delta.compose(base, delete_first) == expected
    end

    test "insert embed" do
      a = [Op.insert(%{"image" => "image.png"}, %{"width" => "300"})]
      b = [Op.retain(1, %{"height" => "200"})]
      expected = [Op.insert(%{"image" => "image.png"}, %{"width" => "300", "height" => "200"})]

      assert Delta.compose(a, b) == expected
    end

    test "delete entire text" do
      a = [Op.retain(4), Op.insert("Hello")]
      b = [Op.delete(9)]
      expected = [Op.delete(4)]

      assert Delta.compose(a, b) == expected
    end

    test "retain more than length of text" do
      a = [Op.insert("Hello")]
      b = [Op.retain(10)]
      expected = [Op.insert("Hello")]

      assert Delta.compose(a, b) == expected
    end

    test "retain empty embed" do
      a = [Op.insert(%{})]
      b = [Op.retain(1)]

      assert Delta.compose(a, b) == a
    end

    test "remove all attributes" do
      a = [Op.insert("A", %{"bold" => true})]
      b = [Op.retain(1, %{"bold" => nil})]
      expected = [Op.insert("A")]

      assert Delta.compose(a, b) == expected
    end

    test "remove all embed attributes" do
      a = [Op.insert(2, %{"bold" => true})]
      b = [Op.retain(1, %{"bold" => nil})]
      expected = [Op.insert(2)]

      assert Delta.compose(a, b) == expected
    end

    test "retain start optimization" do
      a = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true}),
        Op.delete(1)
      ]

      b = [
        Op.retain(3),
        Op.insert("D")
      ]

      expected = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true}),
        Op.insert("D"),
        Op.delete(1)
      ]

      assert Delta.compose(a, b) == expected
    end

    test "retain start optimization split" do
      a = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true}),
        Op.retain(5),
        Op.delete(1)
      ]

      b = [
        Op.retain(4),
        Op.insert("D")
      ]

      expected = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true}),
        Op.retain(1),
        Op.insert("D"),
        Op.retain(4),
        Op.delete(1)
      ]

      assert Delta.compose(a, b) == expected
    end

    test "retain end optimization" do
      a = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true})
      ]

      b = [Op.delete(1)]
      expected = [Op.insert("B"), Op.insert("C", %{"bold" => true})]

      assert Delta.compose(a, b) == expected
    end

    test "retain end optimization join" do
      a = [
        Op.insert("A", %{"bold" => true}),
        Op.insert("B"),
        Op.insert("C", %{"bold" => true}),
        Op.insert("D"),
        Op.insert("E", %{"bold" => true}),
        Op.insert("F")
      ]

      b = [
        Op.retain(1),
        Op.delete(1)
      ]

      expected = [
        Op.insert("AC", %{"bold" => true}),
        Op.insert("D"),
        Op.insert("E", %{"bold" => true}),
        Op.insert("F")
      ]

      assert Delta.compose(a, b) == expected
    end

    test "retain at boundary" do
      a = [Op.insert("ab"), Op.insert("cd")]
      b = [Op.retain(2), Op.delete(1)]
      expected = [Op.insert("abd")]

      assert Delta.compose(a, b) == expected
    end

    test "non-compact" do
      a = [
        Op.insert(""),
        Op.insert("2", %{"link" => "link"}),
        Op.insert("\n")
      ]

      b = [Op.retain(1), Op.delete(1)]
      expected = [Op.insert("2", %{"link" => "link"})]

      assert Delta.compose(a, b) == expected
    end

    test "overlapping delete and retain" do
      a = [
        Op.retain(1),
        Op.retain(2, %{"bold" => true, "author" => "user1"})
      ]

      b = [
        Op.retain(2),
        Op.delete(2, %{"author" => "user2"})
      ]

      assert Delta.compose(a, b) == [
               Op.retain(1),
               Op.retain(1, %{"bold" => true, "author" => "user1"}),
               Op.delete(2, %{"author" => "user2"})
             ]
    end
  end

  describe ".compose/2 (custom embeds)" do
    @describetag custom_embeds: [TestEmbed]

    test "retain an embed with a number" do
      a = [Op.insert(%{"delta" => [Op.insert("a")]})]
      b = [Op.retain(1, %{"bold" => true})]
      expected = [Op.insert(%{"delta" => [Op.insert("a")]}, %{"bold" => true})]

      assert Delta.compose(a, b) == expected
    end

    test "retain a number with an embed" do
      a = [Op.retain(10, %{"bold" => true})]
      b = [Op.retain(%{"delta" => [Op.insert("b")]})]

      expected = [
        Op.retain(%{"delta" => [Op.insert("b")]}, %{"bold" => true}),
        Op.retain(9, %{"bold" => true})
      ]

      assert Delta.compose(a, b) == expected
    end

    test "retain an embed with an embed" do
      a = [Op.retain(%{"delta" => [Op.insert("a")]})]
      b = [Op.retain(%{"delta" => [Op.insert("b")]})]
      expected = [Op.retain(%{"delta" => [Op.insert("ba")]})]

      assert Delta.compose(a, b) == expected
    end

    test "delete a retain" do
      a = [Op.retain(%{"delta" => [Op.insert("a")]})]
      b = [Op.delete(1)]
      expected = [Op.delete(1)]

      assert Delta.compose(a, b) == expected
    end
  end
end

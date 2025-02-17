defmodule Delta.Op do
  alias Delta.Attr
  alias Delta.EmbedHandler

  @type t :: insert_op | retain_op | delete_op

  @typedoc """
  Stand-in type while operators are keyed with String.t() instead of Atom.t()

  `%{insert: String.t() | EmbedHandler.embed(), ...}`
  """
  @type insert_op :: %{required(insert_key) => insert_val, optional(attributes) => attributes_val}
  @typep insert_key :: String.t()
  @typep insert_val :: String.t() | EmbedHandler.embed()

  @typedoc """
  Stand-in type while operators are keyed with String.t() instead of Atom.t()

  `%{retain: pos_integer() | EmbedHandler.embed()}`
  """
  @type retain_op :: %{required(retain_key) => retain_val, optional(attributes) => attributes_val}
  @typep retain_key :: String.t()
  @typep retain_val :: pos_integer() | EmbedHandler.embed()

  @typedoc """
  Stand-in type while operators are keyed with String.t() instead of Atom.t()

  `%{delete: pos_integer()}`
  """
  @type delete_op :: %{
          required(delete_key) => pos_integer,
          optional(attributes) => attributes_val
        }
  @typep delete_key :: String.t()
  @typep delete_val :: pos_integer()

  @typedoc """
  Stand-in type while operators are keyed with String.t() instead of Atom.t()
  """
  @type operation :: insert_key | retain_key | delete_key
  @typep operation_val :: insert_val | retain_val | delete_val

  @typedoc """
  Stand-in type while attributes is keyed with String.t() instead of Atom.t()
  """
  @type attributes :: %{required(String.t()) => attributes_val}
  @typep attributes_val :: map() | false

  @doc ~S"""
  Create a new operation.

  Note that operations _are_ maps, and not structs.

  ## Examples
      iex> Op.new("insert", "Hello", %{"bold" => true})
      %{"insert" => "Hello", "attributes" => %{"bold" => true}}
  """
  @spec new(action :: operation, value :: operation_val, attr :: attributes_val) :: t
  def new(action, value, attr \\ false)

  def new(action, value, %{} = attr) when map_size(attr) > 0 do
    %{action => value, "attributes" => attr}
  end

  def new(action, value, _attr), do: %{action => value}

  @doc ~S"""
  A shorthand for `new("insert", value, attributes)`. See `new/3`.

  ## Examples
      iex> Op.insert("Hello", %{"bold" => true})
      %{"insert" => "Hello", "attributes" => %{"bold" => true}}
  """
  @spec insert(value :: insert_val, attr :: attributes_val) :: insert_op
  def insert(value, attr \\ false), do: new("insert", value, attr)

  @doc ~S"""
  A shorthand for `new("retain", value, attributes)`. See `new/3`.

  ## Examples
      iex> Op.retain(1, %{"bold" => true})
      %{"retain" => 1, "attributes" => %{"bold" => true}}
  """
  @spec retain(value :: retain_val, attr :: attributes_val) :: retain_op
  def retain(value, attr \\ false), do: new("retain", value, attr)

  @doc ~S"""
  A shorthand for `new("delete", value, attributes)`. See `new/3`.

  ## Examples
      iex> Op.delete(1, %{"bold" => true})
      %{"delete" => 1, "attributes" => %{"bold" => true}}
  """
  @spec delete(value :: delete_val, attr :: attributes_val) :: delete_op
  def delete(value, attr \\ false), do: new("delete", value, attr)

  @doc ~S"""
  Returns true if operation has attributes

  ## Examples
      iex> Op.has_attributes?(%{"insert" => "Hello", "attributes" => %{"bool" => true}})
      true

      iex> Op.has_attributes?(%{"insert" => "Hello"})
      false
  """
  @spec has_attributes?(any) :: boolean
  def has_attributes?(%{"attributes" => %{}}), do: true
  def has_attributes?(_), do: false

  @doc ~S"""
  Returns true if operation is of type `type`. Optionally check against more specific `value_type`.

  ## Examples
      iex> Op.insert("Hello") |> Op.type?("insert")
      true

      iex> Op.insert("Hello") |> Op.type?("insert", :string)
      true

      iex> Op.insert("Hello") |> Op.type?("insert", :number)
      false

      iex> Op.retain(1) |> Op.type?("retain", :number)
      true
  """
  @spec type?(op :: t, action :: any, value_type :: any) :: boolean
  def type?(op, action, value_type \\ nil)
  def type?(%{} = op, action, nil) when is_map_key(op, action), do: true
  def type?(%{} = op, action, :map), do: is_map(op[action])
  def type?(%{} = op, action, :string), do: is_binary(op[action])
  def type?(%{} = op, action, :number), do: is_integer(op[action])
  def type?(%{}, _action, _value_type), do: false

  @doc ~S"""
  A shorthand for `type?(op, "insert", type)`. See `type?/3`.

  ## Examples
      iex> Op.insert("Hello") |> Op.insert?()
      true
  """
  @spec insert?(op :: t, type :: any) :: boolean
  def insert?(op, type \\ nil), do: type?(op, "insert", type)

  @doc ~S"""
  A shorthand for `type?(op, "delete", type)`. See `type?/3`.

  ## Examples
      iex> Op.delete(1) |> Op.delete?()
      true
  """
  @spec delete?(op :: t, type :: any) :: boolean
  def delete?(op, type \\ nil), do: type?(op, "delete", type)

  @doc ~S"""
  A shorthand for `type?(op, "insert", type)`. See `type?/3`.

  ## Examples
      iex> Op.retain(1) |> Op.retain?()
      true
  """
  @spec retain?(op :: t, type :: any) :: boolean
  def retain?(op, type \\ nil), do: type?(op, "retain", type)

  @doc ~S"""
  Returns text size.

  ## Examples
      iex> Op.text_size("Hello")
      5

      iex> Op.text_size("🏴󠁧󠁢󠁳󠁣󠁴󠁿")
      1
  """
  @spec text_size(text :: binary) :: non_neg_integer
  def text_size(text) do
    String.length(text)
  end

  @doc ~S"""
  Returns operation size.

  ## Examples
      iex> Op.insert("Hello") |> Op.size()
      5

      iex> Op.retain(3) |> Op.size()
      3
  """
  @spec size(t) :: non_neg_integer
  def size(%{"insert" => text}) when is_binary(text), do: text_size(text)
  def size(%{"delete" => len}) when is_integer(len), do: len
  def size(%{"retain" => len}) when is_integer(len), do: len
  def size(_op), do: 1

  @doc ~S"""
  Takes `length` characters from an operation and returns it together with the
  remaining part in a tuple.

  ## Options

    * `:align` - when `true`, allow moving index left if
      we're likely to split a grapheme otherwise.

  ## Examples
      iex> Op.insert("Hello") |> Op.take(3)
      {%{"insert" => "Hel"}, %{"insert" => "lo"}}

      iex> Op.insert("🏴󠁧󠁢󠁳󠁣󠁴󠁿") |> Op.take(1)
      {%{"insert" => "🏴󠁧󠁢󠁳󠁣󠁴󠁿"}, false}
  """
  @spec take(op :: t, length :: non_neg_integer) :: {t, t | boolean}
  def take(op, length)

  def take(op = %{"insert" => embed}, _length) when not is_bitstring(embed) do
    {op, false}
  end

  def take(op, length) do
    case size(op) - length do
      0 -> {op, false}
      _ -> take_partial(op, length)
    end
  end

  @doc ~S"""
  Gets two embeds' data. An embed is always a [one-key map](https://quilljs.com/docs/delta/#embeds)

  ## Examples
      iex> Op.get_embed_data!(
      ...>   %{"image" => "https://quilljs.com/assets/images/icon.png"},
      ...>   %{"image" => "https://quilljs.com/assets/images/icon2.png"}
      ...> )
      {"image", "https://quilljs.com/assets/images/icon.png", "https://quilljs.com/assets/images/icon2.png"}
  """
  @spec get_embed_data!(map, map) :: {any, any, any}
  def get_embed_data!(a, b) do
    cond do
      not is_map(a) ->
        raise("cannot retain #{inspect(a)}")

      not is_map(b) ->
        raise("cannot retain #{inspect(b)}")

      map_size(a) != 1 and Map.keys(a) != Map.keys(b) ->
        raise("embeds not matched: #{inspect(a: a, b: b)}")

      true ->
        [type] = Map.keys(a)
        {type, a[type], b[type]}
    end
  end

  @spec compose(a :: t, b :: t) :: {t | false, t, t}
  def compose(a, b) do
    {op1, a, op2, b} = next(a, b)

    composed =
      case {info(op1), info(op2)} do
        {{"retain", _type}, {"delete", :number}} ->
          op2

        {{"retain", :map}, {"retain", :number}} ->
          attr = Attr.compose(op1["attributes"], op2["attributes"])
          retain(op1["retain"], attr)

        {{"retain", :number}, {"retain", _type}} ->
          attr = Attr.compose(op1["attributes"], op2["attributes"], true)
          retain(op2["retain"], attr)

        {{"insert", _type}, {"retain", :number}} ->
          attr = Attr.compose(op1["attributes"], op2["attributes"])
          insert(op1["insert"], attr)

        {{action, type}, {"retain", :map}} ->
          {embed_type, embed1, embed2} = get_embed_data!(op1[action], op2["retain"])
          handler = Delta.get_handler!(embed_type)

          composed_embed = %{embed_type => handler.compose(embed1, embed2, action == "retain")}
          keep_nil? = action == "retain" && type == :number
          attr = Attr.compose(op1["attributes"], op2["attributes"], keep_nil?)

          new(action, composed_embed, attr)

        _other ->
          false
      end

    {composed, a, b}
  end

  @spec transform(non_neg_integer, non_neg_integer, t, boolean) ::
          {non_neg_integer, non_neg_integer}
  def transform(offset, index, op, priority) when is_integer(index) do
    length = size(op)

    if insert?(op) and (offset < index or not priority) do
      {offset + length, index + length}
    else
      {offset + length, index}
    end
  end

  @spec transform(a :: t, b :: t, priority :: boolean) :: {t | false, t, t}
  def transform(a, b, priority) do
    {op1, a, op2, b} = next(a, b)

    transformed =
      cond do
        delete?(op1) ->
          false

        delete?(op2) ->
          op2

        # Delegate to embed handler if both are retain ops are
        # embeds of the same type
        retain?(op1, :map) && retain?(op2, :map) &&
            Map.keys(op1["retain"]) == Map.keys(op2["retain"]) ->
          {embed_type, embed1, embed2} = get_embed_data!(op1["retain"], op2["retain"])
          handler = Delta.get_handler!(embed_type)

          embed = %{embed_type => handler.transform(embed1, embed2, priority)}
          attrs = Attr.transform(op1["attributes"], op2["attributes"], priority)
          retain(embed, attrs)

        retain?(op1, :number) && retain?(op2, :map) ->
          attrs = Attr.transform(op1["attributes"], op2["attributes"], priority)
          retain(op2["retain"], attrs)

        true ->
          attrs = Attr.transform(op1["attributes"], op2["attributes"], priority)
          retain(size(op1), attrs)
      end

    {transformed, a, b}
  end

  @spec next(t, t) :: {t, t, t, t}
  defp next(a, b) do
    size = min(size(a), size(b))
    {op1, a} = take(a, size)
    {op2, b} = take(b, size)
    {op1, a, op2, b}
  end

  @spec take_partial(t, non_neg_integer) :: {t, t}
  defp take_partial(op, 0), do: {insert("", op["attributes"]), op}

  defp take_partial(%{"insert" => text} = op, len) do
    length = String.length(text)
    left = String.slice(text, 0, len)
    right = String.slice(text, len, length - len)
    {insert(left, op["attributes"]), insert(right, op["attributes"])}
  end

  defp take_partial(%{"delete" => full} = op, length) do
    {delete(length, op["attributes"]), delete(full - length, op["attributes"])}
  end

  defp take_partial(%{"retain" => full} = op, length) do
    {retain(length, op["attributes"]), retain(full - length, op["attributes"])}
  end

  @spec info(t) :: {String.t(), :number | :string | :map}
  defp info(op) do
    action =
      case op do
        %{"insert" => _} -> "insert"
        %{"retain" => _} -> "retain"
        %{"delete" => _} -> "delete"
      end

    type =
      case op[action] do
        value when is_integer(value) -> :number
        value when is_binary(value) -> :string
        value when is_map(value) -> :map
      end

    {action, type}
  end
end

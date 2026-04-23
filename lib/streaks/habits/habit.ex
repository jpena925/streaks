defmodule Streaks.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Accounts.User
  alias Streaks.Habits.{HabitCompletion, WeeklyNote}

  @qualitative_min 2
  @qualitative_max 5

  @type qualitative_option :: %{
          required(:id) => String.t(),
          required(:color) => String.t(),
          required(:label) => String.t()
        }

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          tracking_mode: :binary | :quantity | :qualitative,
          quantity_low: Decimal.t() | nil,
          quantity_high: Decimal.t() | nil,
          qualitative_options: [qualitative_option()] | nil,
          archived_at: DateTime.t() | nil,
          position: integer() | nil,
          user_id: integer() | nil,
          user: User.t() | Ecto.Association.NotLoaded.t(),
          completions: [HabitCompletion.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habits" do
    field :name, :string
    field :tracking_mode, Ecto.Enum, values: [:binary, :quantity, :qualitative], default: :binary
    field :quantity_low, :decimal, default: Decimal.new("1")
    field :quantity_high, :decimal, default: Decimal.new("10")
    field :qualitative_options, {:array, :map}, default: []
    field :archived_at, :utc_datetime
    field :position, :integer

    belongs_to :user, User
    has_many :completions, HabitCompletion, on_delete: :delete_all
    has_many :weekly_notes, WeeklyNote, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [
      :name,
      :tracking_mode,
      :quantity_low,
      :quantity_high,
      :qualitative_options,
      :archived_at,
      :position
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:quantity_low, greater_than: 0)
    |> validate_number(:quantity_high, greater_than: 0)
    |> validate_quantity_range()
    |> normalize_qualitative_options()
    |> validate_tracking_mode_config()
    |> trim_name()
  end

  defp validate_quantity_range(changeset) do
    low = get_field(changeset, :quantity_low)
    high = get_field(changeset, :quantity_high)

    if low && high && Decimal.compare(low, high) != :lt do
      add_error(changeset, :quantity_high, "must be greater than low value")
    else
      changeset
    end
  end

  defp normalize_qualitative_options(changeset) do
    opts = get_field(changeset, :qualitative_options) || []

    normalized =
      opts
      |> List.wrap()
      |> Enum.map(&normalize_option_map/1)
      |> Enum.reject(&match?(%{id: nil}, &1))

    put_change(changeset, :qualitative_options, normalized)
  end

  defp normalize_option_map(map) when is_map(map) do
    id = Map.get(map, "id") || Map.get(map, :id)
    color = Map.get(map, "color") || Map.get(map, :color) || ""
    label = Map.get(map, "label") || Map.get(map, :label) || ""

    %{id: id, color: String.trim(color), label: String.trim(label)}
  end

  defp validate_tracking_mode_config(changeset) do
    case get_field(changeset, :tracking_mode) do
      :quantity ->
        put_change(changeset, :qualitative_options, [])

      :qualitative ->
        validate_qualitative_options(changeset)

      :binary ->
        put_change(changeset, :qualitative_options, [])
    end
  end

  defp validate_qualitative_options(changeset) do
    opts = get_field(changeset, :qualitative_options) || []
    count = length(opts)

    changeset = validate_qualitative_count(changeset, count)

    if count >= @qualitative_min and count <= @qualitative_max do
      validate_qualitative_entries(changeset, opts)
    else
      changeset
    end
  end

  defp validate_qualitative_count(changeset, count) do
    cond do
      count < @qualitative_min ->
        add_error(
          changeset,
          :qualitative_options,
          "add at least #{@qualitative_min} options"
        )

      count > @qualitative_max ->
        add_error(
          changeset,
          :qualitative_options,
          "at most #{@qualitative_max} options allowed"
        )

      true ->
        changeset
    end
  end

  defp validate_qualitative_entries(changeset, opts) do
    Enum.reduce(opts, changeset, fn opt, cs ->
      cs
      |> validate_option_id(opt[:id])
      |> validate_option_color(opt[:color])
      |> validate_option_label(opt[:label])
    end)
  end

  defp validate_option_id(cs, id) when is_binary(id) and id != "", do: cs

  defp validate_option_id(cs, _) do
    add_error(cs, :qualitative_options, "each option needs a valid id")
  end

  @hex_color ~r/\A#[0-9A-Fa-f]{6}\z/

  defp validate_option_color(cs, color) when is_binary(color) do
    if Regex.match?(@hex_color, color) do
      cs
    else
      add_error(cs, :qualitative_options, "each option needs a color like #22c55e")
    end
  end

  defp validate_option_color(cs, _), do: add_error(cs, :qualitative_options, "invalid color")

  defp validate_option_label(cs, label) when is_binary(label) do
    cond do
      label == "" ->
        add_error(cs, :qualitative_options, "add a short meaning for each color")

      String.length(label) > 80 ->
        add_error(cs, :qualitative_options, "each meaning must be at most 80 characters")

      true ->
        cs
    end
  end

  defp validate_option_label(cs, _), do: add_error(cs, :qualitative_options, "invalid label")

  defp trim_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.trim(name))
    end
  end

  @doc """
  Builds qualitative options from user input (e.g. form params).

  Rows may use placeholder ids like `"new-0"` … `"new-4"` (stable across `phx-change`).
  Call `finalize_qualitative_option_ids/1` on create/update submit to replace placeholders with UUIDs.
  """
  @spec build_qualitative_options_from_params(term()) :: [qualitative_option()]
  def build_qualitative_options_from_params(raw) when is_map(raw) do
    raw
    |> Enum.sort_by(fn {k, _} -> String.to_integer(to_string(k)) end)
    |> Enum.map(fn {_, v} -> v end)
    |> build_qualitative_options_from_params()
  end

  def build_qualitative_options_from_params(raw) when is_list(raw) do
    raw
    |> Enum.map(&normalize_option_map/1)
    |> Enum.reject(fn %{label: l, color: c} -> l == "" and c == "" end)
    |> Enum.map(fn opt ->
      id =
        cond do
          is_binary(opt.id) and opt.id != "" ->
            opt.id

          true ->
            Ecto.UUID.generate()
        end

      %{id: id, color: opt.color, label: opt.label}
    end)
  end

  def build_qualitative_options_from_params(_), do: []

  @doc """
  Replaces `new-*` placeholder ids with UUIDs before persisting.
  """
  @spec finalize_qualitative_option_ids([qualitative_option()]) :: [qualitative_option()]
  def finalize_qualitative_option_ids(opts) do
    Enum.map(opts, fn %{id: id} = o ->
      if is_binary(id) and String.starts_with?(id, "new-") do
        %{o | id: Ecto.UUID.generate()}
      else
        o
      end
    end)
  end

  @doc """
  Returns the hex color for a qualitative option id, or nil if unknown.
  """
  @spec qualitative_color_for_option(t() | map(), String.t()) :: String.t() | nil
  def qualitative_color_for_option(%__MODULE__{qualitative_options: opts}, option_id)
      when is_binary(option_id) and is_list(opts) do
    Enum.find_value(opts, fn opt ->
      id = Map.get(opt, "id") || Map.get(opt, :id)
      c = Map.get(opt, "color") || Map.get(opt, :color)
      if id == option_id, do: c, else: nil
    end)
  end

  def qualitative_color_for_option(_, _), do: nil
end

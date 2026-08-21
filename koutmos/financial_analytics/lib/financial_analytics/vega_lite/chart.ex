defmodule FinancialAnalytics.VegaLite.Chart do
  @moduledoc """
  This module acts as a wrapper around VegaLite to streamline the creation
  of financial visuals. We will be leaning on these VegaLite components
  to render all of our technical analysis charts.
  """

  alias VegaLite, as: Vl

  defstruct [:title, :datasets, :date_field, :view_stack, :width, :height]

  defmodule View do
    defstruct [:layers, :title, :domain_fields, :domain_scaling_factor]

    def new(opts) do
      domain_scaling_factor = Keyword.get(opts, :domain_scaling_factor, 10)

      %__MODULE__{
        layers: [],
        title: Keyword.get(opts, :title),
        domain_fields: Keyword.get(opts, :domain_fields, []),
        domain_scaling_factor: Decimal.new(domain_scaling_factor)
      }
    end

    def add_layer(%__MODULE__{} = view, new_layer) do
      Map.update!(view, :layers, fn existing_layers ->
        [new_layer | existing_layers]
      end)
    end
  end

  def new(title, datasets, opts \\ []) do
    %__MODULE__{
      title: title,
      datasets: datasets,
      view_stack: [],
      date_field: Keyword.get(opts, :date_field, "date"),
      height: Keyword.get(opts, :height, 275),
      width: Keyword.get(opts, :width, 1150)
    }
  end

  def begin_view(%__MODULE__{} = chart, opts \\ []) do
    Map.update!(chart, :view_stack, fn existing_charts ->
      [View.new(opts) | existing_charts]
    end)
  end

  def layer_price(%__MODULE__{} = chart, dataset_key) do
    layer_def =
      Vl.new()
      |> Vl.data(name: dataset_key)
      |> Vl.mark(:area, stroke: "#0284c7", stroke_width: "2", clip: true)
      |> Vl.encode_field(:x, chart.date_field)
      |> Vl.encode_field(:color, "series",
        type: :nominal,
        title: "Price",
        scale: [
          range: ["#7dd3fc"]
        ]
      )

    add_layer_to_last_chart(chart, layer_def)
  end

  def layer_run_detection(%__MODULE__{} = chart, dataset_key, color_mappings) do
    {domain, range} = Enum.unzip(color_mappings)

    layer_def =
      Vl.new()
      |> Vl.data(name: dataset_key)
      |> Vl.mark(:rect, opacity: 0.15)
      |> Vl.encode_field(:x, "date", type: :ordinal)
      |> Vl.encode(:y, value: 0)
      |> Vl.encode(:y2, value: chart.height)
      |> Vl.encode_field(:fill, "series",
        type: :nominal,
        title: "Purchase levels",
        scale: [
          domain: domain,
          range: range
        ]
      )

    add_layer_to_last_chart(chart, layer_def)
  end

  def layer_line(%__MODULE__{} = chart, dataset_key, title, field_sort) do
    layer_def =
      Vl.new()
      |> Vl.data(name: dataset_key)
      |> Vl.mark(:line, stroke: "#f59e0b")
      |> Vl.encode_field(:x, chart.date_field)
      |> Vl.encode_field(:stroke_dash, "series",
        type: :nominal,
        title: title,
        sort: field_sort
      )

    add_layer_to_last_chart(chart, layer_def)
  end

  def layer_bar(%__MODULE__{} = chart, dataset_key) do
    layer_def =
      Vl.new()
      |> Vl.data(name: dataset_key)
      |> Vl.mark(:bar, fill: "#a8a29e", width: [band: 0.5])
      |> Vl.encode_field(:x, chart.date_field)

    add_layer_to_last_chart(chart, layer_def)
  end

  def layer_entry_exit(%__MODULE__{} = chart, dataset_key) do
    layer_def =
      Vl.new()
      |> Vl.data(name: dataset_key)
      |> Vl.mark(:rule, stroke: "#16a34a")
      |> Vl.encode_field(:x, chart.date_field)
      |> Vl.encode(:y, value: 0)
      |> Vl.encode(:y2, value: chart.height)
      |> Vl.encode_field(:stroke, "series",
        type: :nominal,
        title: "Action points",
        scale: [
          range: ["#16a34a", "#dc2626"]
        ],
        sort: ["Market entry", "Market exit"]
      )

    add_layer_to_last_chart(chart, layer_def)
  end

  def render(%__MODULE__{} = chart) do
    total_views = length(chart.view_stack)

    concat_charts =
      chart.view_stack
      |> Enum.with_index(1)
      |> Enum.reduce([], fn {%View{} = view, view_index}, view_acc ->
        ordered_layers = Enum.reverse(view.layers)

        [
          width: chart.width,
          height: chart.height
        ]
        |> Vl.new()
        |> Vl.layers(ordered_layers)
        |> format_view(view, view_index, chart, total_views, view_acc)
      end)

    [
      title: [text: chart.title, font_size: 26],
      spacing: 0,
      bounds: "flush"
    ]
    |> Vl.new()
    |> Vl.datasets_from_values(chart.datasets)
    |> Vl.concat(concat_charts, :vertical)
    |> Vl.resolve(:scale, x: :shared)
    |> Kino.VegaLite.new()
  end

  defp format_view(
         vega_lite_spec,
         %View{} = next_view,
         view_index,
         %__MODULE__{} = chart,
         total_views,
         view_acc
       ) do
    {%{"value" => min}, %{"value" => max}} =
      chart.datasets
      |> Enum.flat_map(fn {field, timeseries_data} ->
        if field in next_view.domain_fields do
          timeseries_data
        else
          []
        end
      end)
      |> Enum.reject(fn data ->
        data
        |> Map.fetch!("value")
        |> is_nil()
      end)
      |> Enum.min_max_by(
        fn data ->
          Map.fetch!(data, "value")
        end,
        Decimal
      )

    range = Decimal.sub(max, min)

    pad =
      next_view.domain_scaling_factor
      |> Decimal.div(100)
      |> Decimal.mult(range)

    min = Decimal.sub(min, pad)
    max = Decimal.add(max, pad)

    view_position = view_position(view_index, total_views)

    x_axis =
      if view_position == :bottom do
        [label_angle: -45, label_font_size: 14, grid: false]
      else
        [labels: false, ticks: false, grid: false]
      end

    y_axis =
      if view_position in [:bottom, :middle] do
        [label_expr: "datum.value == #{max} ? '' : datum.label"]
      else
        [label_expr: "datum.label"]
      end

    formatted_view =
      vega_lite_spec
      |> Vl.encode_field(:x, chart.date_field,
        type: :ordinal,
        time_unit: "yearmonthdate",
        axis: x_axis,
        title: nil
      )
      |> Vl.encode_field(:y, "value",
        type: :quantitative,
        scale: [domain: [min, max]],
        title: next_view.title,
        axis: y_axis
      )

    [formatted_view | view_acc]
  end

  defp view_position(1, _), do: :bottom
  defp view_position(view_index, total_views) when view_index == total_views, do: :top
  defp view_position(_, _), do: :middle

  defp add_layer_to_last_chart(%__MODULE__{} = chart, additional_layer) do
    Map.update!(chart, :view_stack, fn views ->
      List.update_at(views, 0, fn view ->
        View.add_layer(view, additional_layer)
      end)
    end)
  end
end

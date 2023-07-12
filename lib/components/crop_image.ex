defmodule GerbileImv.Component.CropImage do
  use Scenic.Component

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}, {:circle, 3}, {:group, 3}]
  import Evision

  @radius 40
  @hit_radius  20


  @impl Scenic.Component
  def validate(data) do
    if(validate_path(data) && validate_dim(data)) do
      {:ok, data}
    else
      {:error, "invalid build input"}
    end
  end
    
  defp validate_path(data) do
    case data do
      %{path: str} -> if(is_binary(str)) do
          IO.puts("ok string")
          true
        else
          false
        end
      _ -> false
    end
  end

  defp validate_dim(data) do
    case data do
      %{dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}} -> 
        if(is_num(min_x) &&
           is_num(min_y) &&
           is_num(max_x) &&
           is_num(max_y)) do
          true
        else
          false
        end
      _ -> false
    end
  end

  defp validate_dim(data) do
    case data do
      %{pin: {x,y}} -> 
        if(is_num(x) &&
          is_num(y)) do
          true
        else
          false
        end
      _ -> false
    end
  end

  defp is_num(x)do
    is_integer(x) || is_float(x)
  end

  @impl Scenic.Scene
  def init(scene, data, opts) do
    %{path: path} = data
    %{dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}} = data
    %{pin: {x, y}} = data

    img = Evision.imread(path) 
          |> Evision.Mat.to_nx()
    {height, width, _} = Nx.shape(img)
    
    path = Path.expand(path)
    {:ok, file} = path |> File.read
    {:ok, stream} = file |> Scenic.Assets.Stream.Image.from_binary
    Scenic.Assets.Stream.put("loaded_image",stream)
    {_, com_height} = scene.viewport.size
    scale = {com_height/height, com_height/height}
    sc = com_height/height
    data = %{data | dim: %{min_x: min_x*sc, max_x: max_x*sc, min_y: min_y*sc, max_y: max_y*sc}}
    graph = Scenic.Graph.build()
            |> rect({width,height}, fill: {:stream, "loaded_image"}, scale: scale, pin: {x,y}, id: :image)
            |> draw_outline(data)

    scene = Scenic.Scene.assign(scene, :graph, graph)
            |> push_graph(graph)

    :ok = capture_input(scene, [:cursor_pos, :cursor_button, :cursor_scroll])
    scene = Scenic.Scene.assign(scene, :bls, data[:dim])
    closest_vertex(scene, {0,0})
    {:ok, Scenic.Scene.assign(scene, :id, opts[:id])}
  end


  @impl Scenic.Scene
  def handle_input(inp, _, scene) do
    IO.inspect(inp)
    {:noreply, scene}
  end

  defp draw_outline(graph, %{dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}, pin: {x, y}}) do
    graph 
      |> group( &(&1
        |> circle(@radius, translate: {min_x, min_y}, fill: :green)
        |> circle(@radius, translate: {min_x, max_y}, fill: :green)
        |> circle(@radius, translate: {max_x, min_y}, fill: :green)
        |> circle(@radius, translate: {max_x, max_y}, fill: :green)
      ), translate: {x, y}, id: :blots)
  end

  defp closest_vertex(scene, cursor_pos) do
    {:ok, vert} = Scenic.Scene.fetch(scene, :bls)
    mins = for x <- [:min_x, :max_x], y <- [:min_y, :max_y], into: [] do 
      %{vert: [x, y], dist: Scenic.Math.Vector2.distance({vert[x], vert[y]}, cursor_pos)} 
    end
    IO.inspect(mins)
    min = Enum.min_by(mins, &(&1[:dist]))
    if(min[:dist] <= @hit_radius) do 
      min[:vert]
    else
      :none
    end
  end

end

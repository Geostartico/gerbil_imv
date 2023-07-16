defmodule GerbileImv.Component.CropImage do
  use Scenic.Component

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}, {:circle, 3}, {:group, 3}]
  import Evision

  @radius 10
  @hit_radius  20
  @padding 500


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
      %{pin: {x,y}, width: w, height: h} -> 
        if(is_num(x) &&
           is_num(w) &&
           is_num(h) &&
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
  defp clamp(x, mino, maxo) do
    Kernel.max(x, mino) |> Kernel.min(maxo)
  end

  @impl Scenic.Scene
  def init(scene, data, opts) do
    %{path: path} = data
    %{dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}} = data
    %{pin: {x, y}} = data
    %{width: com_width, height: com_height} = data

    img = Evision.imread(path) 
          |> Evision.Mat.to_nx()
    {height, width, _} = Nx.shape(img)

    min_x = clamp(min_x, 0, width)
    max_x = clamp(max_x, min_x, width)
    min_y = clamp(min_y, 0, height)
    max_y = clamp(max_y, min_y, height)
    
    path = Path.expand(path)
    {:ok, file} = path |> File.read
    {:ok, stream} = file |> Scenic.Assets.Stream.Image.from_binary
    Scenic.Assets.Stream.put("loaded_image#{path}",stream)
    scale = {com_width/width, com_width/width}
    sc = com_width/width
    data = %{data | dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}}
    graph = Scenic.Graph.build()
            |> rect({width,height}, fill: {:stream, "loaded_image#{path}"}, scale: scale, pin: {x,y*2}, id: :image, input: [:cursor_button, :cursor_pos])

    scene = Scenic.Scene.assign(scene, :graph, graph)

    graph = graph
            |> draw_outline(data, sc)
    scene = scene 
            |> push_graph(graph)

    #:ok = capture_input(scene, [:cursor_pos, :cursor_button, :cursor_scroll])
    scene = Scenic.Scene.assign(scene, :dim, data[:dim])
    scene = Scenic.Scene.assign(scene, :img, path)
    scene = Scenic.Scene.assign(scene, :bls, data[:dim])
    scene = Scenic.Scene.assign(scene, :clicked, false)
    scene = Scenic.Scene.assign(scene, :scale, sc)
    scene = Scenic.Scene.assign(scene, :pin, {x,y})
    {:ok, Scenic.Scene.assign(scene, :id, opts[:id])}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:btn_left, 1, _, pos = {pos_x, pos_y}}}, _, scene) do
    scene = case closest_vertex(scene, pos, @hit_radius) do 
      {:some, vert = [x, y]}->
        IO.puts("clicked")
        {:ok, dims} = Scenic.Scene.fetch(scene, :dim)
        {:ok, graph} = Scenic.Scene.fetch(scene, :graph)
        {:ok, blots} = Scenic.Scene.fetch(scene, :bls)
        {:ok, pin = {pin_x, pin_y}} = Scenic.Scene.fetch(scene, :pin)
        {:ok, scale} = Scenic.Scene.fetch(scene, :scale)

        scene = Scenic.Scene.assign(scene, :clicked, true)

        pos_x = fn _ ->
          cond do
            x == :min_x ->
              clamp((pos_x - pin_x)/scale, 0, blots[:max_x]-2*@hit_radius)
            x == :max_x -> 
              clamp((pos_x - pin_x)/scale, blots[:min_x]+2*@hit_radius, dims[:max_x])
          end
        end
        pos_y = fn _ ->
          cond do
            y == :min_y ->
              clamp((pos_y - pin_y)/scale, 0, blots[:max_y]-2*@hit_radius)
            y == :max_y -> 
              clamp((pos_y - pin_y)/scale, blots[:min_y]+2*@hit_radius, dims[:max_y])
          end
        end

        blots = blots 
                |> Map.update!(x, pos_x)
                |> Map.update!(y, pos_y)
        scene = Scenic.Scene.assign(scene, :bls, blots)
        graph = draw_outline(graph, %{dim: blots, pin: pin}, scale)
        scene = push_graph(scene, graph)
        scene
      :none -> 
        IO.puts("out")
        scene
    end
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_button, {:btn_left, 0, _, pos = {pos_x, pos_y}}}, _, scene) do
    {:ok, click} = Scenic.Scene.fetch(scene, :clicked)
    scene = Scenic.Scene.assign(scene, :clicked, false)
    {:ok, bls} = Scenic.Scene.fetch(scene, :bls)
    if(click)do
    :ok = Scenic.Scene.send_parent_event(scene, {:crop_changed, bls}  )
    end
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_pos, pos = {pos_x, pos_y}}, _, scene) do
    scene = case Scenic.Scene.fetch(scene, :clicked) do 
      {:ok, true}->
        {:ok, dims} = Scenic.Scene.fetch(scene, :dim)
        {:ok, graph} = Scenic.Scene.fetch(scene, :graph)
        {:ok, blots} = Scenic.Scene.fetch(scene, :bls)
        #IO.inspect(blots)
        {:ok, pin = {pin_x, pin_y}} = Scenic.Scene.fetch(scene, :pin)
        {:ok, scale} = Scenic.Scene.fetch(scene, :scale)
        vert = {:some, [x, y]} = closest_vertex(scene, pos, @padding)
        pos_x = fn _ ->
          cond do
            x == :min_x ->
              clamp((pos_x - pin_x)/scale, 0, blots[:max_x]-2*@hit_radius)
            x == :max_x -> 
              clamp((pos_x - pin_x)/scale, blots[:min_x]+2*@hit_radius, dims[:max_x])
          end
        end
        pos_y = fn _ ->
          cond do
            y == :min_y ->
              clamp((pos_y - pin_y)/scale, 0, blots[:max_y]-2*@hit_radius)
            y == :max_y -> 
              clamp((pos_y - pin_y)/scale, blots[:min_y]+2*@hit_radius, dims[:max_y])
          end
        end


        blots = blots 
                |> Map.update!(x, pos_x)
                |> Map.update!(y, pos_y)
        scene = Scenic.Scene.assign(scene, :bls, blots)
        IO.puts("hello")
        graph = draw_outline(graph, %{dim: blots, pin: pin}, scale)
        scene = push_graph(scene, graph)
        scene
      {:ok, false} -> 
        #IO.puts("not clicked")
        scene
    end
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input(inp, _, scene) do
    IO.inspect(inp)
    {:noreply, scene}
  end

  defp draw_outline(graph, %{dim: %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}, pin: {x, y}}, scale) do
    graph 
      |> group( &(&1
        |> circle(@radius, translate: {min_x*scale, min_y*scale}, fill: :green)
        |> circle(@radius, translate: {min_x*scale, max_y*scale}, fill: :green)
        |> circle(@radius, translate: {max_x*scale, min_y*scale}, fill: :green)
        |> circle(@radius, translate: {max_x*scale, max_y*scale}, fill: :green)
      ), translate: {x, y}, id: :blots)
  end

  defp closest_vertex(scene, cursor_pos, dist) do
    {:ok, vert} = Scenic.Scene.fetch(scene, :bls)
    {:ok, pin} = Scenic.Scene.fetch(scene, :pin)
    {:ok, scale} = Scenic.Scene.fetch(scene, :scale)
    mins = for x <- [:min_x, :max_x], y <- [:min_y, :max_y], into: [] do 
      %{vert: [x, y], dist: Scenic.Math.Vector2.distance(Scenic.Math.Vector2.mul({vert[x], vert[y]},scale) |> Scenic.Math.Vector2.add( pin) , cursor_pos)} 
    end
    #IO.inspect(mins)
    min = Enum.min_by(mins, &(&1[:dist]))
    IO.inspect(min)
    if(min[:dist] <= dist) do 
      {:some, min[:vert]}
    else
      #IO.inspect(min)
      :none
    end
  end

end

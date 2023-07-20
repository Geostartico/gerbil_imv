defmodule GerbileImv.Component.Image do
  use Scenic.Component

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}]
  import Evision
  @scroll_factor  0.01
  @speed 0.00001
  @speed_tran 100


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
          true
        else
          false
        end
      _ -> false
    end
  end

  defp validate_dim(data) do
    case data do
      %{dim: {width, height}} -> if((is_integer(width) || is_float(width)) && (is_integer(height) || is_float(height))) do
          true
        else
          false
        end
      _ -> false
    end
  end

  @impl Scenic.Scene
  def init(scene, data, opts) do
    %{path: path} = data
    %{dim: {com_width, com_height}} = data

    img = Evision.imread(path) 
          |> Evision.Mat.to_nx()
    {height, width, _} = Nx.shape(img)
    
    path = Path.expand(path)
    {:ok, file} = path |> File.read
    {:ok, stream} = file |> Scenic.Assets.Stream.Image.from_binary
    #Scenic.Assets.Stream.put("loaded_image",stream)
    #IO.puts("STREAM INSERTED")
    Scenic.Assets.Stream.put("loaded_image#{path}",stream)
    scale = {com_width/width, com_width/width}
    graph = Scenic.Graph.build()
            |> rect({width,height}, fill: {:stream, "loaded_image#{path}"}, scale: scale, pin: {0,0}, id: :image, input: [:cursor_scroll])

    scene = Scenic.Scene.assign(scene, :graph, graph)
            |> push_graph(graph)

    IO.inspect(opts[:id])
    :ok = capture_input(scene, [:key])
    scene = Scenic.Scene.assign(scene, :tran, {0,0})
            |> Scenic.Scene.assign(:dim, {width,height})
            |> Scenic.Scene.assign(:scale, scale)
            |> Scenic.Scene.assign(:path, path)
    {:ok, Scenic.Scene.assign(scene, :id, opts[:id])}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_scroll, {{_, sc}, {pos_x, pos_y}}}, _, scene) do
    scene = if(sc != 0)do
      {:ok, {offset_x, offset_y}} = Scenic.Scene.fetch(scene, :tran)

      {:ok, {scale, scale}} = Scenic.Scene.fetch(scene, :scale)
      {:ok, {width, height}} = Scenic.Scene.fetch(scene, :dim)
      {:ok, graph} = Scenic.Scene.fetch(scene, :graph)
      {:ok, path} = Scenic.Scene.fetch(scene, :path)
      scale = if(sc < 0) do
        scale+@scroll_factor
      else
        scale-@scroll_factor
      end
      offset_x = offset_x - pos_x * scale * @speed * -sc * width 
      offset_y = offset_y - pos_y * scale * @speed * -sc * height
      scene = Scenic.Scene.assign(scene, :scale, {scale,scale})
      scene = Scenic.Scene.assign(scene, :tran, {offset_x,offset_y})
      graph = Scenic.Graph.modify(graph, :image, &rect(&1,{width,height}, fill: {:stream, "loaded_image#{path}"}, scale: scale, pin: {0,0}, id: :image, translate: {offset_x,offset_y}))
      Scenic.Scene.push_graph(scene,graph)
    else
      scene
    end
    {:noreply, scene}
  end
  @impl Scenic.Scene
  def handle_input({:key, {key, i, _}}, _, scene) do
    if(i != 0) do
      {:ok, {offset_x, offset_y}} = Scenic.Scene.fetch(scene, :tran)

      {:ok, {scale, scale}} = Scenic.Scene.fetch(scene, :scale)
      {:ok, {width, height}} = Scenic.Scene.fetch(scene, :dim)
      {:ok, path} = Scenic.Scene.fetch(scene, :path)

      {move_x, move_y} = case key do
        :key_h -> {1, 0}
        :key_j -> {0, -1}
        :key_k -> {0, 1}
        :key_l -> {-1, 0}
        _ -> {0,0}
      end

      offset_x = offset_x + move_x * @speed_tran 
      offset_y = offset_y + move_y * @speed_tran 

      {:ok, graph} = Scenic.Scene.fetch(scene, :graph)

      scene = Scenic.Scene.assign(scene, :tran, {offset_x,offset_y})
      graph = Scenic.Graph.modify(graph, :image, &rect(&1,{width,height}, fill: {:stream, "loaded_image#{path}"}, scale: scale, pin: {0,0}, id: :image, translate: {offset_x,offset_y}))
      
      {:noreply, Scenic.Scene.push_graph(scene,graph)}
      else
        {:noreply, scene}
      end
  end

  @impl Scenic.Scene
  def handle_input(inp, _, scene) do
    IO.inspect(inp)
    {:noreply, scene}
  end

end

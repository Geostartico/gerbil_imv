defmodule GerbileImv.Component.Image do
  use Scenic.Component

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}]
  import Evision


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
    Scenic.Assets.Stream.put("loaded_image",stream)
    scale = {com_height/height, com_height/height}
    graph = Scenic.Graph.build()
            |> rect({width,height}, fill: {:stream, "loaded_image"}, scale: scale, pin: {0,0})

    scene = Scenic.Scene.assign(scene, :graph, graph)
    scene = push_graph(scene, graph)

    IO.inspect(opts[:id])
    :ok = capture_input(scene, [:key, :cursor_pos, :cursor_button, :cursor_scroll])
    {:ok, Scenic.Scene.assign(scene, :id, opts[:id])
}
  end

  @impl Scenic.Scene
  def handle_input(inp, _, scene) do
    IO.inspect(inp)
    {:noreply, scene}
  end

end

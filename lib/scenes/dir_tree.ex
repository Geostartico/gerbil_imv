defmodule GerbileImv.Scene.DirTree do
    use Scenic.Scene
    alias Scenic.Graph
    import Scenic.Primitives
    import Scenic.Components
    alias GerbileImv.Component.Nav
    alias GerbileImv.Component.Notes
    alias Scenic.Assets.Stream.Bitmap
    @bottom_y 20
    @bottom_x 20
    @button_width 100
    @button_height 40
    @font_size 11
    @spacing 10
    @graph Graph.build()
      #|> Nav.add_to_graph(__MODULE__)

    defp graph(), do: @graph

    @impl Scenic.Scene
    def init( scene, param, _opts ) do
      IO.puts("SI PARTE")
      {:ok, view_port} = Scenic.ViewPort.info(:main_viewport)
      %{size: size} = view_port
      {win_width, win_height} = size
      scene = case param do
        %{path: str} when is_binary(str) -> cd_path(scene,str)
        _ -> cd_path(scene,"~/")
      end
      {:ok,ls} = File.ls()
      ls = [".." | ls]
      graph = graph() 
              |> button("home", id: :home_button, translate: {10,win_height - @bottom_y},height: @bottom_y)
              |> render_buttons(ls,{0,0}, 0, 0, win_width, win_height)
      scene = push_graph( scene, graph )
      scene = assign(scene, :num_labels, 0)
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event({:click, :home_button}, _, scene) do
      IO.puts("cliccato: home")
      Scenic.ViewPort.set_root(scene.viewport, GerbileImv.Scene.DirTree, %{})
      {:noreply, scene}
    end

    @impl Scenic.Scene
    def handle_event({:click, id}, _, scene) when is_binary(id) do
      IO.puts("cliccato: #{id}")
      if(Path.expand(id) |> File.dir?()) do
        Scenic.ViewPort.set_root(scene.viewport, GerbileImv.Scene.DirTree, %{path: id <> "/"})
      else 
        raise "NOT YET IMPLEMENTED"
      end
      {:noreply, scene}
    end

    @impl Scenic.Scene
    def handle_event(_,_,_) do
      raise "Unrecognized event"
    end

    defp cd_path(scene, str) when is_binary(str) do
      str = str <> case fetch(scene, :curdir) do
        {:ok, relative} -> relative
        _ -> ""
      end
      curpath = Path.expand(str)
      :ok = File.cd(curpath)
      scene = assign(scene, :curdir, str)
      scene
    end

    defp render_buttons(graph, [head | tail], {offsetx, offsety}, begin_x, begin_y, max_x, max_y) do
      cond do

        offsetx + @button_width < 0 || offsety + @button_height < 0 ->
          cond do 
            offsetx + @button_width < 0 ->
            render_buttons(graph, tail, {offsetx + @button_width + @spacing + 10, offsety}, begin_x, begin_y, max_x, max_y)
            true ->
            render_buttons(graph, tail, {offsetx, offsety + @button_height + @spacing}, begin_x, begin_y, max_x, max_y)
          end

        offsetx + @button_width > max_x - @bottom_x ->
          render_buttons(graph, tail, {begin_x, offsety + @button_height + @spacing}, begin_x, begin_y, max_x, max_y)

        offsety + @button_height > max_y - @bottom_y -> graph

        true -> graph |> add_button(offsetx, offsety, head) |> render_buttons(tail, {offsetx+@button_width + 10, offsety}, begin_x, begin_y, max_x, max_y)

      end
    end

    defp render_buttons(graph, [], _, _, _, _, _) do
      graph
    end
    defp add_button(graph, offsetx, offsety, label) do
      case String.length(label) do
        l when l > @button_width/@font_size -> graph |> button(String.slice(label, 0..trunc(@button_width/@font_size)-1), id: label, translate: {offsetx,offsety},height: @button_height, width: @button_width,style: [text_size: @font_size])
        _ -> graph |> button(label, id: label, translate: {offsetx,offsety},height: @button_height, width: @button_width,style: [text_size: @font_size, font: :roboto_mono])
      end
    end
end

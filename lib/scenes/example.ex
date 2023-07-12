  defmodule GerbileImv.Scene.Example do
    use Scenic.Scene
    alias Scenic.Graph
    import Scenic.Primitives
    import Scenic.Components
    alias GerbileImv.Component.Nav
    alias GerbileImv.Component.Notes
    alias Scenic.Assets.Stream.Bitmap

    @graph Graph.build()
      |> text("Hello World", font_size: 22, translate: {20, 80})
      |> button("Do Something", translate: {20, 180}, id: :spawn_button)
      |> Notes.add_to_graph("esempio di cosa")
      #|> Nav.add_to_graph(__MODULE__)

    defp graph(), do: @graph

    @impl Scenic.Scene
    def init( scene, _param, _opts ) do
      IO.inspect(Evision.imread("/home/geostartico/Documents/c.html"))
      img = Evision.imread("/home/geostartico/Pictures/gyro.jpg") 
            |> Evision.Mat.to_nx()
      {height, width, _} = Nx.shape(img)
      #IO.inspect(Nx.shape(img))
      #stream = Bitmap.build(:rgb, width, height)
      #img = Nx.to_list(img)
      ##IO.inspect(img)
      #stream = insert_line_stream(img,stream, 0)
      #stream = Bitmap.commit(stream)
      #Scenic.Assets.Stream.put("loaded_image",stream)
      #IO.puts("#{img}")
      {:ok, file} = "/home/geostartico/Pictures/gyro.jpg" |> File.read
      IO.inspect(file)
      {:ok, stream} = file |> Scenic.Assets.Stream.Image.from_binary
      Scenic.Assets.Stream.put("loaded_image",stream)
      {:ok, view_port} = Scenic.ViewPort.info(:main_viewport)
      %{size: size} = view_port
      {win_width, win_height} = size
      scale = {500/width, 500/height}
      graph = graph() 
              |> rect({width,height}, fill: {:stream, "loaded_image"}, scale: scale, pin: {100,100})
      scene = push_graph( scene, graph )
      scene = assign(scene, :num_labels, 0)
      :ok = capture_input(scene, [:key, :cursor_pos, :cursor_button, :cursor_scroll])
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event({:click, :spawn_button}, _, scene) do
      {:ok, lab} = fetch(scene, :num_labels)
      lab = lab + 1
      scene = assign(scene, :num_labels, lab)
      IO.puts("cliccato: #{lab}")
      graph = insert_text(lab, graph())
      scene = push_graph(scene, graph)
      #IO.puts(Integer.to_string(length(Scenic.Graph.get(graph(), :questo))) <> "")
      {:noreply, scene}
    end

    @impl Scenic.Scene
    def handle_input(inp, _, scene) do
      IO.inspect(inp)
      {:noreply, scene}
    end

    def handle_event(_,_,_) do
      raise "Unrecognized event"
    end

    defp insert_text(i, g) when i > 0 do
      g = text(g,"cliccato e aggiunto testo", translate: {20 + 10*i, 20 + 10*i}, id: :questo)
      insert_text(i-1,g)
    end

    defp insert_text(0, g) do
      g
    end

    defp insert_line_stream([head | tail], stream, line) do
      stream = insert_column_stream(head, stream, line, 0)
      line = line+1
      insert_line_stream(tail, stream, line)
    end

    defp insert_line_stream([], stream, _) do
      stream
    end

    defp insert_column_stream([head | tail], stream, line, column) do
      #IO.puts("color:")
      #IO.inspect(head)
      [b,g,r] = head
      color = {:color_rgb,{r, g, b}}
      stream = Bitmap.put(stream, column,line,color)
      column = column + 1
      insert_column_stream(tail, stream, line, column)
    end

    defp insert_column_stream([], stream, _, _) do
      stream
    end

  end

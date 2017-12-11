defmodule Scenic.Template.Input.Checkbox do
  use Scenic.Template.Input

#  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Line
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Text
  alias Scenic.Template.Input
  alias Scenic.Template.Input.Checkbox
  alias Scenic.ViewPort.Input.Tracker

#  import IEx

  @default_radius     3

  @text_color         :white
  @box_color          :antique_white
  @check_color        :cornflower_blue

  @font               {:roboto, 16}

  @hit_target_color   {:dark_green, 0}

  #----------------------------------------------------------------------------
  def build(data, opts \\ [] )

  def build({chx, text}, opts ) when is_boolean(chx) and is_bitstring(text) do
    # build the checkbox graph

    opts = opts
    |> Keyword.put_new(:input_value, chx)
    |> Keyword.put_new(:font, @font)

    Input.build( opts )
    |> Group.add_to_graph(fn(graph) ->
      graph
      |> Rectangle.add_to_graph({{-2,-2}, 140, 16}, color: @hit_target_color)
      |> RoundedRectangle.add_to_graph({{-2,-2}, 16, 16, @default_radius}, color: @box_color)

      |> Group.add_to_graph(fn(graph) ->
        graph
        |> Line.add_to_graph({{2,2}, {10,10}})
        |> Line.add_to_graph({{2,10}, {10,2}})
      end, tags: [:checkmark], hidden: !chx, color: @check_color, line_width: 4)
    end, translate: {0, -11})
    
    |> Text.add_to_graph({{18,0}, text}, color: @text_color )
    |> Graph.put_event_filter(0, {Checkbox, :filter_input})
  end


  #----------------------------------------------------------------------------
  def filter_input(event, %Primitive{uid: uid} = checkbox, graph) do
    case event do

      {:mouse_button, :left, :press, _, _ } ->
        uids = Graph.gather_uids(graph, checkbox)
        Tracker.Click.start( :left, checkbox, uids )
        {:stop, graph}


      {:click, _, _pos} ->
        # find the checkmark for this checkbox
        [checkmark] = Graph.find(graph, uid, tag: :checkmark)
        checkmark_uid = Primitive.get_uid( checkmark )

        new_hidden = !Primitive.get_style(checkmark, :hidden)
        new_value = !new_hidden

        graph = Graph.modify(graph, checkmark_uid, fn(p) ->
          Primitive.put_style(p, :hidden, new_hidden)
        end)

        # set the value into the input. This is done outside of a Graph.modify block
        # as it doesn't affect the visuals of the graph and shouldn't cause a redraw
        graph = Graph.get( graph, uid )
        |> Input.put_value( new_value )
        |> ( &Graph.put( graph, uid, &1 ) ).()

        {:continue, {:value_changed, checkbox, !new_hidden}, graph}

      event ->
        {:continue, event, graph}
    end
  end

end
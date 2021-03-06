defmodule Lodestone do
  def get_page_data(url) do
    {:ok, response} = HTTPoison.get(url)

    playersOnPage = Floki.find(response.body, ".area_inner_header")
                    |> Floki.find(".player_name_area")
                    |> Floki.find("a")
                    |> Enum.map(&(Floki.text &1))

    ranksOnPage = Floki.find(response.body, ".area_inner_header")
                  |> Floki.find(".player_name_area")
                  |> Floki.find(".fc_member_status")
                  |> Enum.map(&(Floki.text &1))
                  |> Enum.map(&(String.strip &1))

    List.zip([playersOnPage, ranksOnPage])
  end

  @doc ~S"""
  Return preformed urls
  ## Examples
    iex> Lodestone.generate_pages("")
    ["?page=1", "?page=2", "?page=3", "?page=4", "?page=5", "?page=6", "?page=7",
    "?page=8", "?page=9", "?page=10"]
  """
  def generate_pages(url) do
    Enum.to_list 1..10
    |> Enum.map(&("#{url}?page=#{&1}"))
  end

  def get_freecompany_data(fc_id) do
    generate_pages("http://na.finalfantasyxiv.com/lodestone/freecompany/#{fc_id}/member/")
    |> Enum.map(&(get_page_data &1))
    |> Enum.reduce(fn(x, acc) -> acc = acc ++ x end)
  end

  @doc ~S"""
  Ends the json list of elements
  ## Examples
    iex> Lodestone.roster_to_json([], 0)
    "{\n  \"type\" : \"KTLabel\",\n  \"id\" : \"END\",\n  \"location\" : { \"x\" : 0, \"y\": 0, \"z\" : 3},\n  \"size\" : {\"width\" : 123, \"height\" : 123}\n}\n"
  """
  def roster_to_json([], num_elems) do
    """
    {
      "type" : "KTLabel",
      "id" : "END",
      "location" : { "x" : 0, "y": #{num_elems *  123}, "z" : 3},
      "size" : {"width" : 123, "height" : 123}
    }
    """
  end

  def roster_to_json([head | tail], num_elems) do
    {name, rank} = head
    json = """
    {
      "type" : "KTButton",
      "id" : "#{name} #{rank}",
      "location" : { "x" : 0, "y": #{num_elems *  123}, "z" : 3},
      "size" : {"width" : 123, "height" : 123}
    },
    """
    json <> roster_to_json(tail, num_elems + 1)
  end

  def get_freecompany_officers(fc_id) do
  	get_freecompany_data(fc_id)
  	|> Enum.filter(fn({name, rank}) -> String.contains?(rank, "-O") end)
  end

  def get_freecompany_data_as_kurt(fc_id) do
    roster = get_freecompany_data(fc_id)
             |> roster_to_json(0)

    json = """
    {
      "ui" : [
      {
        "type" : "KTWidget",
        "location" : {"x" : 300, "y" : 200, "z" : 0},
        "size" : {"width" : 123, "height" : 163},
        "external" : "http://snowie.github.io/kurt/testwidget.html"
      },
      {
        "type" : "KTPanel",
        "location" : {"x" : 0, "y" : 0, "z" : 0},
        "size" : {"width" : 123, "height" : 123},
        "id" : "RosterPanel",
        "children" : [
          {
            "type" : "KTLabel",
            "location" : {"x" : 0, "y" : 0, "z" : 3},
            "size" : {"width" : 123, "height": 123},
            "id" : "v ROSTER v"
          },
          {
            "type" : "KTInputField",
            "location" : {"x" : 0, "y" : 83, "z": 3},
            "size" : {"width" : 123, "height" : 40}
            "id" : "Roster Search"
          }
        ]
      },
      {
        "type" : "KTScrollView",
        "location" : { "x" : 0, "y": 123, "z" : 3},
        "size" : {"width" : 123, "height" : 339},
        "panelsize": {"width" : 200, "height" : 60000},
        "scrollable" : { "horizontal" : false, "vertical" : true},
        "children" : [
          #{roster}
        ]
      }
      ]
    }
    """
  end
end

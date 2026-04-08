defmodule DiagramaSavanaWeb.PageController do
  use DiagramaSavanaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

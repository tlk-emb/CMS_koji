defmodule HomePageWeb.CategoryView do
  use HomePageWeb, :view
  alias HomePage.Accounts
  alias HomePage.Pages

  def current_user(conn) do
    Accounts.current_user(conn)
  end

  # アイテムが何行目かを返す(%{"行数" => アイテムの数}というマップを返す)
  def how_line(items, line, map, list) do
    # lineの初期値1,mapの初期値%{},listの初期値[]
    case items do
      [%{line: hl} | tail] when abs(hl) == line ->
        how_line(tail, line, map, [hl | list])
      [%{line: hl} | tail] when abs(hl) > line ->
        how_line(tail, line + 1,
          Map.merge(map, %{"#{line}" => length(list)}), [hl])
      [] ->
        Map.merge(map, %{"#{line}" => length(list)})
    end
  end

  def parse_markdown(markdown) do
    Earmark.as_html!(markdown)
  end

  def current_category(conn) do #リンク先のクエリにカテゴリのurl名が必要
    conn.request_path
    |> URI.decode()
    |> String.split("index/")
    |> tl
    |> hd
  end
  def current_category_preview(conn) do #リンク先のクエリにカテゴリのurl名が必要
    conn.request_path
    |> URI.decode()
    |> String.split("preview/")
    |> tl
    |> hd
  end
  def current_category_color(url) do
    category = Pages.get_category_by_url(url)
    [bcolor, ccolor] = [category.bcolor, category.ccolor]
  end

  defp list_create(num) do
    [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
    |> Enum.reject(fn(x) -> x > num end)
  end

end

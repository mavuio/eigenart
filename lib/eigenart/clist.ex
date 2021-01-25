defmodule Eigenart.Clist do
  @moduledoc """
  The Content List context.
  """
  import Eigenart.EaHelpers, warn: false
  import Eigenart.Ce, only: [is_ce: 1]
  alias Eigenart.Ce
  import Pit

  def append(nil, item), do: append([], item)

  def append(clist, item) when is_list(clist) and is_ce(item) do
    clist ++ [item]
  end

  def append(clist, path, item) when is_binary(path) and is_list(clist) and is_ce(item) do
    path
    |> get_access_list_for_path()
    |> case do
      [] ->
        append(clist, item)

      path ->
        update_in(clist, path, fn items ->
          append(items, item)
        end)
    end
  end

  def remove(clist, uid) when is_list(clist) and is_binary(uid) do
    clist
    |> Enum.filter(fn a -> a["uid"] != uid end)
  end

  def remove(clist, path, uid) when is_binary(path) and is_list(clist) and is_binary(uid) do
    path
    |> get_access_list_for_path()
    |> case do
      [] ->
        remove(clist, uid)

      path ->
        update_in(clist, path, fn items ->
          remove(items, uid)
        end)
    end
  end

  def duplicate(clist, uid) when is_list(clist) and is_binary(uid) do
    clist
    |> Enum.map(fn ce ->
      if(ce["uid"] == uid) do
        [ce, Ce.duplicate_ce(ce)]
      else
        [ce]
      end
    end)
    |> Enum.concat()
  end

  def duplicate(clist, path, uid) when is_binary(path) and is_list(clist) and is_binary(uid) do
    get_access_list_for_path(path)
    |> case do
      [] ->
        duplicate(clist, uid)

      path ->
        update_in(clist, path, fn items ->
          duplicate(items, uid)
        end)
    end
  end

  def get_ce(clist, path, uid) when is_list(clist) and is_binary(path) and is_binary(uid) do
    get_in(clist, get_access_list_for_path_and_uid(path, uid))
    |> flatten()
    |> case do
      [el] -> el
      _ -> nil
    end
  end

  def get_clist(clist, path) when is_list(clist) and is_binary(path) do
    get_access_list_for_path(path)
    |> case do
      [] ->
        clist

      pathparts ->
        get_in(clist, pathparts)
        # |> pit!(list <- [list])
    end
  end

  def get_access_list_for_path_and_uid(path, uid) when is_binary(uid) and is_binary(path) do
    get_access_list_for_path(path) ++ [Access.filter(&(&1["uid"] == uid))]
  end

  def get_access_list_for_path(path) when is_binary(path) do
    path
    |> get_path_as_list()
    |> Enum.flat_map(fn {idx, fieldname} ->
      [
        Access.filter(&(&1["uid"] == idx)),
        Access.key(fieldname, [])
      ]
    end)
  end

  def get_path_as_list(nil), do: []
  def get_path_as_list(""), do: []
  def get_path_as_list("-"), do: []
  def get_path_as_list("root"), do: []
  def get_path_as_list(path) when is_list(path), do: path

  def get_path_as_list(path) when is_binary(path) do
    path
    |> String.trim("-")
    |> String.split("-")
    |> Enum.filter(fn
      "root" -> false
      _ -> true
    end)
    |> Enum.map(fn pathpart ->
      pathpart
      |> String.split(".")
      |> List.to_tuple()
    end)
  end

  def moveItem(fromPos, offset, list) do
    offset =
      case offset do
        0 -> 0
        offset when offset > 0 -> offset + 1
        offset when offset < 0 -> offset - 1
      end

    list
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      if index == fromPos do
        {item, index + offset}
      else
        {item, index}
      end
    end)
    |> Enum.sort(fn {_, index1}, {_, index2} -> index1 <= index2 end)
    |> Enum.map(fn {item, _} -> item end)
  end

  def move(clist, uid, direction)
      when is_binary(direction) and is_binary(uid) and is_list(clist) do
    idx = Enum.find_index(clist, &(&1["uid"] == uid))

    offset =
      case direction do
        "up" -> -1
        "down" -> 1
        _ -> 0
      end

    moveItem(idx, offset, clist)
  end

  def move(nil, _uid, _direction), do: []

  def move(clist, path, uid, direction)
      when is_binary(direction) and is_binary(path) and is_list(clist) and is_binary(uid) do
    path
    |> get_access_list_for_path()
    |> case do
      [] ->
        move(clist, uid, direction)

      path ->
        update_in(clist, path, fn items ->
          move(items, uid, direction)
        end)
    end
  end

  def replace(clist, path, uid, data)
      when is_map(data) and is_binary(path) and is_list(clist) and is_binary(uid) do
    access_list = get_access_list_for_path_and_uid(path, uid)

    put_in(clist, access_list, data)
  end

  def replace(clist, path, data)
      when is_list(data) and is_binary(path) and is_list(clist) do
    access_list = get_access_list_for_path(path)

    put_in(clist, access_list, data)
  end

  def flatten([head | tail]), do: flatten(head) ++ flatten(tail)
  def flatten([]), do: []
  def flatten(element), do: [element]
end

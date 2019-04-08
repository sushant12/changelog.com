defmodule ChangelogWeb.Admin.MetacastControllerTest do
  use ChangelogWeb.ConnCase

  alias Changelog.Metacast

  @valid_attrs %{name: "Polyglot"}
  @invalid_attrs %{name: ""}

  @tag :as_admin
  test "lists all metacasts", %{conn: conn} do
    p1 = insert(:metacast)
    p2 = insert(:metacast)

    conn = get(conn, admin_metacast_path(conn, :index))

    assert html_response(conn, 200) =~ ~r/Metacasts/
    assert String.contains?(conn.resp_body, p1.name)
    assert String.contains?(conn.resp_body, p2.name)
  end

  @tag :as_admin
  test "renders form to create new metacast", %{conn: conn} do
    conn = get(conn, admin_metacast_path(conn, :new))
    assert html_response(conn, 200) =~ ~r/new/
  end

  @tag :as_admin
  test "creates metacast and redirects", %{conn: conn} do
    conn = post(conn, admin_metacast_path(conn, :create), metacast: @valid_attrs, next: admin_metacast_path(conn, :index))

    assert redirected_to(conn) == admin_metacast_path(conn, :index)
    assert count(Metacast) == 1
  end

  @tag :as_admin
  test "does not create with invalid attributes", %{conn: conn} do
    count_before = count(Metacast)
    conn = post(conn, admin_metacast_path(conn, :create), metacast: @invalid_attrs)

    assert html_response(conn, 200) =~ ~r/error/
    assert count(Metacast) == count_before
  end

  @tag :as_admin
  test "renders form to edit metacast", %{conn: conn} do
    metacast = insert(:metacast)

    conn = get(conn, admin_metacast_path(conn, :edit, metacast))
    assert html_response(conn, 200) =~ ~r/edit/i
  end

  @tag :as_admin
  test "updates metacast and redirects", %{conn: conn} do
    metacast = insert(:metacast)

    conn = put(conn, admin_metacast_path(conn, :update, metacast), metacast: @valid_attrs)

    assert redirected_to(conn) == admin_metacast_path(conn, :index)
    assert count(Metacast) == 1
  end

  @tag :as_admin
  test "does not update with invalid attributes", %{conn: conn} do
    metacast = insert(:metacast)
    count_before = count(Metacast)

    conn = put(conn, admin_metacast_path(conn, :update, metacast), metacast: @invalid_attrs)

    assert html_response(conn, 200) =~ ~r/error/
    assert count(Metacast) == count_before
  end

  test "requires user auth on all actions", %{conn: conn} do
    metacast = insert(:metacast)

    Enum.each([
      get(conn, admin_metacast_path(conn, :index)),
      get(conn, admin_metacast_path(conn, :new)),
      post(conn, admin_metacast_path(conn, :create), metacast: @valid_attrs),
      get(conn, admin_metacast_path(conn, :edit, metacast)),
      put(conn, admin_metacast_path(conn, :update, metacast), metacast: @valid_attrs)
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end

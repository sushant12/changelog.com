defmodule ChangelogWeb.Helpers.AdminHelpers do
  use Phoenix.HTML

  alias Changelog.Repo
  alias ChangelogWeb.TimeView
  alias ChangelogWeb.Helpers.SharedHelpers

  def error_class(form, field), do: if(form.errors[field], do: "error", else: "")

  def hidden_class(condition), do: if(condition, do: "hidden", else: "")

  def error_message(form, field) do
    case form.errors[field] do
      {message, _} ->
        content_tag :div, class: "ui pointing red basic label" do
          message
        end

      nil ->
        ""
    end
  end

  def file_toggle_buttons() do
    content_tag(:span) do
      [
        content_tag(:a, "(use url)", href: "javascript:void(0);", class: "field-action use-url"),
        content_tag(:a, "(use file)",
          href: "javascript:void(0);",
          class: "field-action use-file",
          style: "display: none;"
        )
      ]
    end
  end

  def filter_select(filter, options) when is_binary(filter),
    do: filter_select(String.to_atom(filter), options)

  def filter_select(filter, options) do
    content_tag(:select, class: "ui fluid selection dropdown js-filter") do
      Enum.map(options, fn {value, label} ->
        args =
          if filter == value do
            [value: value, selected: true]
          else
            [value: value]
          end

        content_tag(:option, label, args)
      end)
    end
  end

  def help_icon(help_text, classes \\ "") do
    ~e"""
    <i class="help circle icon fluid <%= classes %>" data-popup="true" data-variation="wide" data-content="<%= help_text %>"></i>
    """
  end

  def info_icon(info_text) do
    ~e"""
    <i class="info circle icon fluid" data-popup="true" data-variation="wide" data-content="<%= info_text %>"></i>
    """
  end

  def icon_link(icon_name, options) do
    options = Keyword.put(options, :class, "ui icon button")
    link(content_tag(:i, "", class: "#{icon_name} icon"), options)
  end

  def modal_icon_button(view_module, icon_name, title, modal_name, assigns, id) do
    modal_id = "#{modal_name}-modal-#{id}"
    form_id = "#{modal_name}-form-#{id}"
    assigns = Map.merge(assigns, %{modal_id: modal_id, form_id: form_id})
    modal = Phoenix.View.render(view_module, "_#{modal_name}_modal.html", assigns)

    ~e"""
    <button
      type="button"
      data-modal="#<%= modal_id %>"
      class="ui icon button js-modal"
      title="<%= title %>">
        <i class="<%= icon_name %> icon"></i>
    </button>
    <%= modal %>
    """
  end

  def is_persisted(struct), do: is_integer(struct.id)

  def is_loaded(nil), do: false
  def is_loaded(%Ecto.Association.NotLoaded{}), do: false
  def is_loaded(_association), do: true

  def label_with_clear(attr, text) do
    content_tag(:label, for: attr) do
      [
        content_tag(:span, text),
        content_tag(:a, "(clear)", href: "javascript:void(0);", class: "field-action js-clear")
      ]
    end
  end

  # Attempts to load an associated record on a form. Starts with direct
  # relationship on form data, then tries querying Repo.
  def load_from_form(form, module, relationship) do
    form_data = Map.get(form.data, relationship)
    foreign_key = "#{relationship}_id"

    record_id =
      Map.get(form.data, String.to_existing_atom(foreign_key)) || form.params[foreign_key]

    cond do
      is_loaded(form_data) -> form_data
      is_nil(record_id) -> nil
      true -> Repo.get(module, record_id)
    end
  end

  def next_param(conn, default \\ nil), do: Map.get(conn.params, "next", default)

  def download_count(ep_or_pod) do
    ep_or_pod.download_count
    |> round()
    |> SharedHelpers.comma_separated()
  end

  def reach_count(ep_or_pod) do
    if ep_or_pod.reach_count > ep_or_pod.download_count do
      SharedHelpers.comma_separated(ep_or_pod.reach_count)
    else
      download_count(ep_or_pod)
    end
  end

  def semantic_calendar_field(form, field) do
    ~e"""
    <div class="ui calendar">
      <div class="ui input left icon">
        <i class="calendar icon"></i>
        <%= text_input(form, field, name: "", id: "") %>
        <%= hidden_input(form, field) %>
      </div>
    </div>
    """
  end

  def submit_button(type, text, next \\ "") do
    content_tag(:button, text,
      class: "ui #{type} fluid basic button",
      type: "submit",
      name: "next",
      value: next
    )
  end

  def ts(ts), do: TimeView.ts(ts)
  # See time.js for supported styles
  def ts(ts, style), do: TimeView.ts(ts, style)

  def up_or_down_class(a, b) when is_integer(a) and is_integer(b) do
    if a > b do
      "green"
    else
      "red"
    end
  end

  def yes_no_options do
    [{"Yes", true}, {"No", false}]
  end
end

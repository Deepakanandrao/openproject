# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ResourceWorkPackageList < PersistedView
  include ResourceManagement::Categorized

  # Name of the work-package filter that represents a manually hand-picked
  # selection. Items live in the query's `ordered_work_packages` and the
  # filter restricts the result set to exactly those (operator `ow`).
  MANUAL_FILTER_NAME = "manual_sort"

  validate :query_must_be_work_package_query

  # See `UserCard#build_default_query` for context. The work-package Query
  # uses `new_default` so the standard defaults (status filter, sort, etc.)
  # are applied — otherwise validation would fail on missing attributes.
  # The `::` prefix disambiguates from `ActiveRecord::AttributeMethods::Query`
  # which is in scope inside ActiveRecord models.
  def build_default_query
    ::Query.new_default(project:, user: principal)
  end

  # Translates the configure form's serialized filter selection and the
  # automatic/manual toggle into the backing work-package query. Called by
  # the SetAttributes service on both create and update; the modified query
  # is persisted alongside the view through the `autosave` association.
  def apply_query_configuration(filters_json:, filter_mode:)
    query = effective_query
    return if query.nil?

    query.name = configured_query_name
    query.filters.clear

    if manual_mode?(filter_mode)
      configure_manual(query)
    else
      configure_automatic(query, filters_json)
    end
  end

  # Whether this view's items are hand-picked rather than filtered. Drives
  # the sub header's add control (dropdown vs. plain allocate button).
  def manually_picked?
    effective_query&.manually_sorted? || false
  end

  private

  def manual_mode?(filter_mode)
    filter_mode.to_s == "manual"
  end

  def configured_query_name
    I18n.t("resource_management.work_package_list.query_name", name:)
  end

  def configure_manual(query)
    query.add_filter(MANUAL_FILTER_NAME, "ow", [])
    query.sort_criteria = [%w[manual_sorting asc], %w[id asc]]
  end

  def configure_automatic(query, filters_json)
    # Leaving a manual sort in place would require ordered_work_packages that
    # no longer make sense once the view is filtered again, so reset it.
    query.sort_criteria = [%w[id asc]] if query.manually_sorted?

    parse_filters(filters_json).each do |filter|
      query.add_filter(filter[:attribute], filter[:operator], filter[:values])
    end
  end

  def parse_filters(filters_json)
    return [] if filters_json.blank?

    ::Queries::ParamsParser::APIV3FiltersParser.parse(filters_json)
  rescue JSON::ParserError
    []
  end

  def query_must_be_work_package_query
    resolved = effective_query
    return if resolved.nil? || resolved.is_a?(::Query)

    errors.add(:query, I18n.t(:must_be_work_package_query))
  end
end

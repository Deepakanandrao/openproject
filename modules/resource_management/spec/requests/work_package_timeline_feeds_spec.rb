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

require "spec_helper"

RSpec.describe "Work package timeline feeds", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:wp) { create(:work_package, project:, subject: "Develop route optimization") }
  shared_let(:view) do
    ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user).tap do |v|
      v.update!(query: v.build_default_query.tap { |q| q.name = "Timeline" })
    end
  end

  before { login_as user }

  describe "resources" do
    it "returns the view's work packages as FullCalendar resources with rendered html" do
      get timeline_resources_project_resource_planner_view_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      ids = body["resources"].map { |r| r["id"].to_i }
      expect(ids).to include(wp.id)
      cell = body["resources"].find { |r| r["id"].to_i == wp.id }
      expect(cell.dig("extendedProps", "html")).to include("Develop route optimization")
    end

    it "denies users without access" do
      login_as create(:user)
      get timeline_resources_project_resource_planner_view_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end

  describe "events" do
    shared_let(:assignee) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] }).tap do |u|
        create(:user_working_hours, user: u, valid_from: Date.new(2026, 1, 1))
      end
    end
    shared_let(:allocation_a) do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
    end
    shared_let(:allocation_b) do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
    end

    it "returns allocations as FullCalendar events flagged overbooked" do
      get timeline_events_project_resource_planner_view_path(project, planner, view,
                                                             start: "2026-05-25", end: "2026-07-01", format: :json)

      expect(response).to have_http_status(:ok)
      events = response.parsed_body["events"]
      expect(events.map { |e| e["resourceId"].to_i }).to all(eq(wp.id))
      expect(events).to all(include("start", "end"))
      expect(events.map { |e| e.dig("extendedProps", "overbooked") }).to include(true)
    end
  end
end

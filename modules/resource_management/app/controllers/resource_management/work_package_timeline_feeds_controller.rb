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

module ::ResourceManagement
  # JSON feeds backing the resource-timeline. Cell/bar content is rendered
  # server-side as Primer HTML and embedded for the controller's render hooks.
  class WorkPackageTimelineFeedsController < BaseController
    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_resource_planner
    before_action :find_view

    def timeline_resources
      resources = @view.work_packages.map do |work_package|
        {
          id: work_package.id,
          title: work_package.subject,
          extendedProps: { html: render_cell(work_package) }
        }
      end

      render json: { resources: }
    end

    def timeline_events # rubocop:disable Metrics/AbcSize
      allocations = allocations_by_work_package.values.flatten
      overbooked = ResourceAllocation.overbooked_ids(allocations)
      visible = ResourceAllocation.visible_principal_ids(allocations, current_user)

      events = allocations.map do |allocation|
        {
          id: allocation.id,
          resourceId: allocation.entity_id,
          start: allocation.start_date.iso8601,
          end: (allocation.end_date + 1).iso8601, # FullCalendar treats the end as exclusive
          extendedProps: {
            overbooked: overbooked.include?(allocation.id),
            html: render_bar(allocation, visible)
          }
        }
      end

      render json: { events: }
    end

    private

    def render_bar(allocation, visible_principal_ids)
      ResourcePlannerViews::WorkPackageTimeline::AllocationBarComponent
        .new(allocation:, visible_principal_ids:)
        .render_in(view_context)
    end

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(:resource_planner_id))
    end

    def find_view
      @view = @resource_planner.children.find(params.expect(:id))
      render_404 unless @view.is_a?(ResourceWorkPackageTimeline)
    end

    def render_cell(work_package)
      ResourcePlannerViews::WorkPackageTimeline::ResourceCellComponent
        .new(work_package:, allocations: allocations_for(work_package),
             project: @project, resource_planner: @resource_planner, view: @view)
        .render_in(view_context)
    end

    def allocations_by_work_package
      @allocations_by_work_package ||=
        ResourceAllocation.allocated_for_work_packages(@view.work_packages.to_a)
    end

    def allocations_for(work_package)
      allocations_by_work_package.fetch(work_package.id, [])
    end
  end
end

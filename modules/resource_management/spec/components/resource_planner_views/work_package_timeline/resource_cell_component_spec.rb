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

RSpec.describe ResourcePlannerViews::WorkPackageTimeline::ResourceCellComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:view) { ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user) }
  shared_let(:work_package) do
    create(:work_package, project:, subject: "Develop route optimization", estimated_hours: 80)
  end

  before { login_as(user) }

  it "renders the subject, type and the allocation summary" do
    allocation = build_stubbed(:resource_allocation, entity: work_package, allocated_time: 72 * 60)

    render_inline(described_class.new(work_package:, allocations: [allocation],
                                      project:, resource_planner: planner, view:))

    expect(page).to have_text("Develop route optimization")
    expect(page).to have_text(/#{work_package.type.name}/i)
    expect(page).to have_text("72")
    expect(page).to have_text("90%")
  end
end

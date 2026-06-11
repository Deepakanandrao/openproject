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

require "rails_helper"

RSpec.describe Backlogs::BacklogComponent, type: :component do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  let(:project) { create(:project, types: [type_feature]) }
  let(:bucket) { create(:backlog_bucket, project:) }

  def render_component(buckets: [], inbox_work_packages: [])
    render_inline described_class.new(
      inbox_work_packages:,
      buckets:,
      project:,
      current_user: user
    )
  end

  describe "total counter" do
    context "when buckets contain only open work packages" do
      let!(:work_packages) do
        create_list(:work_package, 2, project:, backlog_bucket: bucket,
                                      type: type_feature, status: default_status,
                                      priority: default_priority, position: 1)
      end

      it "counts all bucket work packages" do
        buckets = BacklogBucket.for_project(project)
        render_component(buckets:)
        expect(page).to have_css(".Counter", text: "2")
      end
    end

    context "when buckets contain a mix of open and closed work packages" do
      let!(:open_wp) do
        create(:work_package, project:, backlog_bucket: bucket,
                              type: type_feature, status: default_status,
                              priority: default_priority, position: 1)
      end
      let!(:closed_wp) do
        create(:work_package, project:, backlog_bucket: bucket,
                              type: type_feature, status: closed_status,
                              priority: default_priority, position: 2)
      end

      it "counts only displayed (non-closed) work packages" do
        buckets = BacklogBucket.for_project(project)
        render_component(buckets:)
        expect(page).to have_css(".Counter", text: "1")
      end
    end
  end
end

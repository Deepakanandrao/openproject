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

RSpec.describe Backlogs::MigrateVersionSprintJournalsJob, type: :model do
  let(:project) { create(:project) }
  let(:wp1) { create(:work_package, project:) }
  let(:wp2) { create(:work_package, project:) }

  subject(:perform) { described_class.new.perform(wp_version_map) }

  describe "#perform" do
    context "with multiple work packages" do
      let(:wp_version_map) do
        {
          wp1.id.to_s => "Sprint A",
          wp2.id.to_s => "Sprint B"
        }
      end

      it "creates a journal entry for each work package authored by the system user" do
        perform
        expect(wp1.reload.last_journal.user).to eq(User.system)
        expect(wp2.reload.last_journal.user).to eq(User.system)
      end

      it "sets the cause type to system_update" do
        perform
        expect(wp1.reload.last_journal.cause_type).to eq("system_update")
        expect(wp2.reload.last_journal.cause_type).to eq("system_update")
      end

      it "sets the cause feature to sprint_migration" do
        perform
        expect(wp1.reload.last_journal.cause_feature).to eq("sprint_migration")
        expect(wp2.reload.last_journal.cause_feature).to eq("sprint_migration")
      end

      it "stores the originating version name in the cause" do
        perform
        expect(wp1.reload.last_journal.cause["version_name"]).to eq("Sprint A")
        expect(wp2.reload.last_journal.cause["version_name"]).to eq("Sprint B")
      end

      it "suppresses journal notifications" do
        allow(Journal::NotificationConfiguration).to receive(:with).and_call_original
        perform
        expect(Journal::NotificationConfiguration).to have_received(:with).with(false)
      end
    end

    context "when the map contains an id that no longer exists" do
      let(:wp_version_map) do
        {
          "0" => "Ghost Sprint",
          wp1.id.to_s => "Sprint A"
        }
      end

      it "skips the missing id and still journals the existing work package" do
        expect { perform }.not_to raise_error
        expect(wp1.reload.last_journal.cause["version_name"]).to eq("Sprint A")
      end
    end
  end
end

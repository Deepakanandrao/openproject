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

module ResourcePlannerViews
  module WorkPackageTimeline
    # Renders one allocation's bar content. Principals the current user may not
    # see are anonymised, mirroring AllocatedMembersComponent's visibility rule.
    class AllocationBarComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include AvatarHelper

      AVATAR_SIZE = 20

      def initialize(allocation:, visible_principal_ids: nil)
        super
        @allocation = allocation
        @visible_principal_ids = visible_principal_ids
      end

      private

      attr_reader :allocation, :visible_principal_ids

      def hours_label
        t("resource_management.allocation.hours", value: allocation.allocated_hours.round)
      end

      def filter_based?
        allocation.filter_based?
      end

      def principal_visible?
        return false unless allocation.user_assigned?
        return true if visible_principal_ids.nil?

        visible_principal_ids.include?(allocation.principal_id)
      end

      def label
        if filter_based?
          allocation.filter_name
        elsif principal_visible?
          allocation.principal&.name
        else
          t("resource_management.work_package_allocations_dialog.hidden_user")
        end
      end

      # Resolving the candidate query can fail for an incomplete filter; fall back
      # to no badge rather than erroring the whole timeline.
      def candidate_count
        return 0 unless filter_based?

        allocation.candidate_query.results.count
      rescue StandardError
        0
      end

      def candidate_badge?
        candidate_count.positive?
      end

      def candidate_label
        t("resource_management.work_package_list.allocated_members.additional", count: candidate_count)
      end

      def avatar
        if filter_based? || !principal_visible?
          render(Primer::Beta::Octicon.new(icon: :"person-add", size: :small))
        else
          render(Primer::Beta::Avatar.new(src: avatar_url(allocation.principal),
                                          alt: allocation.principal.name,
                                          size: AVATAR_SIZE))
        end
      end
    end
  end
end

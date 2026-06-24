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

module ResourcePlannerViews::UserCardList
  # Modelled on Users::HoverCardComponent
  class CardComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    MULTI_VALUE_DISPLAY_LIMIT = 3

    def initialize(user:, details_path:, remove_path: nil, utilization: nil)
      super

      @user = user
      @details_path = details_path
      @remove_path = remove_path
      @utilization = utilization
    end

    def render?
      @user&.visible?(User.current)
    end

    def status_label
      helpers.full_user_status(@user)
    end

    def status_scheme
      @user.active? ? :success : :attention
    end

    def utilization?
      !@utilization.nil?
    end

    def utilization_label
      helpers.number_to_percentage(@utilization, precision: 0)
    end

    def working_hours_summary
      return t("resource_management.user_card_list.working_hours.blank") if working_hours.blank?

      if (hours = working_hours.uniform_daily_hours_label)
        t("resource_management.user_card_list.working_hours.uniform",
          hours:,
          days: working_hours.working_days_count,
          range: working_hours.working_day_ranges(abbreviated: true))
      else
        working_hours.working_days_summary
      end
    end

    def card_custom_fields
      @card_custom_fields ||= UserCustomFieldSection
                                .with_filled_fields_for(@user, visible_on_user_card: true)
                                .flat_map(&:last)
    end

    private

    def working_hours
      return @working_hours if defined?(@working_hours)

      @working_hours = UserWorkingHours.for_user(@user).current
    end

    def render_value_labels(value)
      values = Array(value)
      remaining = values.size - MULTI_VALUE_DISPLAY_LIMIT

      labels = values.first(MULTI_VALUE_DISPLAY_LIMIT).map do |item|
        render(Primer::Beta::Label.new(scheme: :accent, mr: 1)) { item }
      end

      if remaining > 0
        labels << render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
          t("resource_management.user_card_list.card.multi_value_more", count: remaining)
        end
      end

      safe_join(labels, " ")
    end

    def card_options
      {
        classes: "op-user-card",
        test_selector: "op-user-card",
        p: 3,
        border: true,
        border_radius: 2,
        overflow: :hidden,
        data: {
          controller: "resource-management--user-card",
          "resource-management--user-card-url-value": @details_path
        }
      }
    end
  end
end

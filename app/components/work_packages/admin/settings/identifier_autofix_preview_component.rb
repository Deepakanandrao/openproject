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

module WorkPackages
  module Admin
    module Settings
      class IdentifierAutofixPreviewComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers

        DISPLAY_COUNT = 5

        # projects_data: array of hashes from ProjectHandleSuggestionGenerator
        # Each hash: { project:, current_identifier:, suggested_handle:, error_reason: }
        def initialize(projects_data:)
          super()
          @displayed = projects_data.first(DISPLAY_COUNT)
          @remaining_count = [projects_data.size - DISPLAY_COUNT, 0].max
        end

        private

        attr_reader :displayed, :remaining_count

        def error_label(error_reason)
          case error_reason
          when :too_long
            I18n.t("admin.settings.work_packages_identifier.autofix_preview.error_too_long")
          when :special_characters
            I18n.t("admin.settings.work_packages_identifier.autofix_preview.error_special_characters")
          end
        end
      end
    end
  end
end

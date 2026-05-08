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

module WorkPackage::Exports
  module Macros
    class WorkPackagesLinkHandler < OpenProject::TextFormatting::Matchers::LinkHandlers::WorkPackages
      def applicable?
        return false unless hash_trigger? && matcher.prefix.blank?

        if WorkPackage::SemanticIdentifier.numeric_id?(matcher.identifier)
          true
        elsif WorkPackage::SemanticIdentifier.semantic_id?(matcher.identifier)
          Setting::WorkPackageIdentifier.semantic_mode_active?
        else
          false
        end
      end

      # PDF rendering walks Markly nodes via `app/models/exports/pdf/common/macro.rb`
      # rather than the `PatternMatcherFilter` preload pipeline, so each semantic
      # reference does its own `find_by_display_id` round-trip. A cache miss
      # returns nil so the matcher emits literal text rather than a mention
      # pointing at a non-existent identifier.
      def call
        if WorkPackage::SemanticIdentifier.semantic_id?(matcher.identifier)
          wp = WorkPackage.find_by_display_id(matcher.identifier)
          return nil unless wp

          render_link(wp.display_id, matcher)
        else
          render_link(matcher.identifier.to_i.to_s, matcher)
        end
      end

      def render_link(data_id, matcher)
        # `data_id` is regex-constrained at the matcher layer (numeric `\d+`
        # or semantic `[A-Z][A-Z0-9_]*-\d+` per `ID_ROUTE_CONSTRAINT`) and
        # for semantic input is sourced from `wp.display_id`. Escape both
        # interpolated values so a future widening of the constraint, or a
        # caller that bypasses the matcher, cannot regress into HTML
        # attribute injection.
        escaped_id = ERB::Util.html_escape(data_id)
        link = "#{matcher.sep}#{escaped_id}"
        %(<mention class="mention" data-id="#{escaped_id}" data-type="work_package" data-text="#{link}">#{link}</mention>)
      end
    end

    class Links < OpenProject::TextFormatting::Matchers::ResourceLinksMatcher
      def self.link_handlers
        [WorkPackagesLinkHandler]
      end

      # Faster inclusion check before the full regex is being applied.
      # Matches `#1`, `##42`, `#PROJ-7` openings — semantic-only bodies
      # must reach the regex too.
      def self.applicable?(content)
        /#[A-Z\d]/.match(content)
      end
    end
  end
end

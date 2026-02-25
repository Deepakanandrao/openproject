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
  # Scans all projects for identifiers that do not meet alphanumeric handle
  # requirements and generates a short uppercase suggestion for each.
  #
  # A "problematic" identifier is one that:
  #   - contains any character outside [a-zA-Z0-9], or
  #   - is longer than 10 characters
  #
  # This service is designed so the data source can be swapped out once the
  # project_handles data model exists (replace Project.all scan with a join on
  # ProjectHandle where current: true).
  class ProjectHandleSuggestionGenerator
    HANDLE_MAX_LENGTH = 10
    VALID_HANDLE_PATTERN = /\A[a-zA-Z0-9]{1,10}\z/

    # Returns an array of hashes for projects with problematic identifiers:
    #   [{ project:, current_identifier:, suggested_handle:, error_reason: }, ...]
    #
    # error_reason is one of: :too_long, :special_characters
    def self.call
      new.call
    end

    def call
      projects = Project.all.to_a
      problematic = projects.select { |p| problematic?(p.identifier) }
      generate_suggestions(problematic)
    end

    private

    def problematic?(identifier)
      return false if identifier.blank?

      identifier.length > HANDLE_MAX_LENGTH || identifier.match?(/[^a-zA-Z0-9]/)
    end

    def error_reason(identifier)
      if identifier.length > HANDLE_MAX_LENGTH
        :too_long
      else
        :special_characters
      end
    end

    def generate_suggestions(projects)
      used_handles = Set.new

      projects.map do |project|
        base = handle_from_name(project.name)
        handle = unique_handle(base, used_handles)
        used_handles << handle

        {
          project:,
          current_identifier: project.identifier,
          suggested_handle: handle,
          error_reason: error_reason(project.identifier)
        }
      end
    end

    # Derives a short uppercase handle from the project name by taking the
    # first letter of each word (acronym style).
    # e.g. "Flight Planning Algorithm" => "FPA"
    #      "Fly & Sky"                 => "FS"
    #      "arcanos-web"               => "AW" (falls back when name is blank)
    def handle_from_name(name)
      words = name.to_s.scan(/[a-zA-Z0-9]+/)
      return "P" if words.empty?

      acronym = words.map { |w| w[0] }.join.upcase # rubocop:disable Rails/Pluck
      acronym.slice(0, HANDLE_MAX_LENGTH)
    end

    def unique_handle(base, used_handles)
      candidate = base
      return candidate unless used_handles.include?(candidate)

      counter = 2
      loop do
        suffix = counter.to_s
        candidate = "#{base.slice(0, HANDLE_MAX_LENGTH - suffix.length)}#{suffix}"
        break unless used_handles.include?(candidate)

        counter += 1
      end

      candidate
    end
  end
end

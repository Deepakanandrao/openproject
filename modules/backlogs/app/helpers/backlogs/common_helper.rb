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

module Backlogs
  module CommonHelper
    def user_allowed?(permission)
      current_user.allowed_in_project?(permission, project)
    end

    def backlog_bucket_creation_allowed?
      user_allowed?(:create_sprints)
    end

    def sprint_creation_allowed?
      user_allowed?(:create_sprints) &&
        !project.receive_shared_sprints?
    end

    def sprint_management_allowed?
      user_allowed?(:share_sprint)
    end

    def backlog_filters
      RequestStore.fetch(:backlog_filters) { Backlogs::BacklogFilters.from_params(params) }
    end

    def backlog_filter_params
      backlog_filters.to_h
    end

    def filter_fields_for(selector_type)
      except = selector_type == :buckets ? :bucket_ids : :sprint_ids
      backlog_filters.to_inputs(except:)
    end
  end
end

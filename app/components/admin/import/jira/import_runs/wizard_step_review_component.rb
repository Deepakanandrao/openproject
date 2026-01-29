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

module Admin::Import::Jira::ImportRuns
  class WizardStepReviewComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Admin::Import::Jira::ImportRunsHelper

    def imported_data
      [
        projects_label(imported_projects_count),
        work_packages_label(imported_issues_count),
        statuses_label(imported_statuses_count),
        types_label(imported_types_count)
      ].map { |label| { label:, checked: true } }
    end

    def imported_projects_count
      OpenProjectJiraReference
        .where(jira_import: model, op_entity_class: "Project", uses_existing: false)
        .count
    end

    def imported_issues_count
      OpenProjectJiraReference
        .where(jira_import: model, op_entity_class: "WorkPackage", uses_existing: false)
        .count
    end

    def imported_statuses_count
      OpenProjectJiraReference
        .where(jira_import: model, op_entity_class: "Status", uses_existing: false)
        .count
    end

    def imported_types_count
      OpenProjectJiraReference
        .where(jira_import: model, op_entity_class: "Type", uses_existing: false)
        .count
    end
  end
end

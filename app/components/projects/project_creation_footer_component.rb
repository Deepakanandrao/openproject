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

module Projects
  class ProjectCreationFooterComponent < StepWizard::FooterComponent
    include OpPrimer::ComponentHelpers

    private

    def progress_bar_args
      {
        visibility: current_step_index === 0 ? :hidden : :visible
      }
    end

    def back_button_args
      {
        hidden: true
      }
    end

    def cancel_button_args
      {
        href: projects_path
      }
    end

    def continue_button_args
      {
        form: form_identifier,
        name: "next_section"
      }
    end

    def submit_button_args
      {
        form: form_identifier,
        name: "finish",
        value: "true"
      }
    end
  end
end

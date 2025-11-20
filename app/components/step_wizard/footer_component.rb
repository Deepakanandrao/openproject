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

module StepWizard
  class FooterComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(form_identifier:, total_steps:, current_step_index:)
      super

      @form_identifier = form_identifier
      @total_steps = total_steps
      @current_step_index = current_step_index
    end

    private

    attr_reader :total_steps, :current_step_index, :form_identifier

    def progress_percentage
      return 0 if total_steps.zero?

      ((current_step_index + 1).to_f / total_steps * 100).round
    end

    def previous_step
      return nil if current_step_index.zero?

      current_step_index - 1
    end

    def next_step
      return nil if current_step_index >= total_steps - 1

      current_step_index + 1
    end

    def first_step?
      current_step_index.zero?
    end

    def last_step?
      current_step_index >= total_steps - 1
    end

    def progress_bar_args
      {}
    end

    def back_button_args
      {}
    end

    def cancel_button_args
      {}
    end

    def continue_button_args
      {}
    end

    def submit_button_args
      {}
    end
  end
end

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
  module Settings
    module Backlogs
      class SharingForm < ApplicationForm
        SHARING_OPTIONS = %w(no_sharing receive_shared).freeze
        SHARING_SCOPE_OPTIONS = %w(share_all_projects share_subprojects).freeze

        form do |f|
          f.select_list(
            name: :sprint_sharing,
            label: Project.human_attribute_name(:sprint_sharing),
            input_width: :medium,
            data: {
              target_name: "sprint_sharing_scope",
              "show-when-value-selected-target": "cause"
            }
          ) do |list|
            list.option(
              value: nil,
              label: I18n.t("projects.settings.backlog_sharing.options.share_sprints"),
              selected: model.sprint_sharing.in?(SHARING_SCOPE_OPTIONS)
            )
            SHARING_OPTIONS.each do |option|
              list.option(
                value: option,
                label: I18n.t("projects.settings.backlog_sharing.options.#{option}"),
                selected: option == model.sprint_sharing
              )
            end
          end

          f.radio_button_group(
            name: :sprint_sharing,
            label: I18n.t("projects.settings.backlog_sharing.sharing_scope"),
            # Would have been nicer to use `hidden:` here, but that hides the component wrapper,
            # while the stimulus `effect` target is bound to the inner fieldset, because `data:`
            # is forwarded there. Since the hidden state and the stimulus `effect` target end up
            # on different elements, stimulus cannot unhide the fieldset reliably.
            # Using `class: "d-none"` ends up on the same fieldset as the stimulus `effect` target.
            # One advantage of the `effect` target being on the fieldset is that, disabling the
            # fieldset will also disable the radio buttons inside it.
            class: ("d-none" if model.sprint_sharing.in?(SHARING_OPTIONS)),
            data: {
              target_name: "sprint_sharing_scope",
              value: "",
              visibility_class: "d-none",
              "show-when-value-selected-target": "effect"
            }
          ) do |group|
            SHARING_SCOPE_OPTIONS.each do |option|
              group.radio_button(
                value: option,
                checked: checked?(option),
                label: I18n.t("projects.settings.backlog_sharing.options.#{option}"),
                caption: I18n.t("projects.settings.backlog_sharing.options.#{option}_caption")
              )
            end
          end

          f.submit(
            name: :submit,
            label: I18n.t("button_save"),
            scheme: :primary
          )
        end

        def checked?(option)
          option == model.sprint_sharing ||
          (option == "share_all_projects" && !model.sprint_sharing.in?(SHARING_SCOPE_OPTIONS))
        end
      end
    end
  end
end

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

class Users::WorkingHours::DaysAndHoursForm < ApplicationForm
  form do |form|
    form.html_content do
      render(Primer::Beta::Subhead.new(spacious: true)) do |component|
        component.with_heading(tag: :div, size: :medium) do
          I18n.t("users.working_hours.form.title_days_and_hours")
        end
      end
    end

    form.group(layout: :horizontal, mb: 2) do |group|
      UserWorkingHours::DAYS.each do |day|
        group.hidden name: "working_hours[#{day}]", value: 0
        group.check_box name: "day_enabled_#{day}",
                        data: { day: day, action: "users--working-hours-form#dayToggled" },
                        checked: day_enabled?(day),
                        label: full_day_name(day),
                        label_arguments: { mr: 3 }
      end
    end

    form.radio_button_group(name: "hours_mode", label: I18n.t("users.working_hours.form.hours_mode_label"), mb: 2) do |group|
      group.radio_button(
        label: I18n.t("users.working_hours.form.same_hours_mode"),
        value: "same",
        checked: all_same_hours?,
        data: { action: "users--working-hours-form#hoursModeChanged" }
      )
      group.radio_button(
        label: I18n.t("users.working_hours.form.individual_hours_mode"),
        value: "individual",
        checked: !all_same_hours?,
        data: { action: "users--working-hours-form#hoursModeChanged" }
      )
    end

    form.text_field name: :shared_hours,
                    label: I18n.t("users.working_hours.form.work_hours"),
                    input_width: :large,
                    value: shared_hours, # TODO: format with `h`
                    data: {
                      "users--working-hours-form-target": "sharedHoursInput",
                      action: "input->users--working-hours-form#hoursChanged blur->users--working-hours-form#hoursFormatted"
                    },
                    trailing_visual: { text: { text: I18n.t("users.working_hours.form.per_day") } }
    # wrapper_data_attributes: { "users--working-hours-form-target": "sameHoursSection" }

    UserWorkingHours::DAYS.each do |day|
      form.text_field name: "#{day}_hours",
                      label: UserWorkingHours.human_attribute_name("#{day}_hours"),
                      value: day_hours(day), # TODO: format with `h`
                      input_width: :large,
                      data: {
                        "users--working-hours-form-target": "dayHoursInput",
                        day: day,
                        action: "input->users--working-hours-form#hoursChanged blur->users--working-hours-form#hoursFormatted"
                      },
                      disabled: !day_enabled?(day)
    end

    form.text_field name: :total_available_hours,
                    label: I18n.t("users.working_hours.form.total_available_hours"),
                    input_width: :large,
                    disabled: true,
                    data: { "users--working-hours-form-target": "totalAvailableHoursDisplay" },
                    trailing_visual: { text: { text: I18n.t("users.working_hours.form.per_week") } }
  end

  private

  def day_enabled?(day)
    model.public_send(day) > 0
  end

  def day_hours(day)
    model.public_send("#{day}_hours")
  end

  def all_same_hours?
    enabled = UserWorkingHours::DAYS.select { |d| day_enabled?(d) }
    return true if enabled.empty?

    enabled.map { |d| day_hours(d) }.uniq.one?
  end

  def shared_hours
    first_enabled = UserWorkingHours::DAYS.find { |d| day_enabled?(d) }
    first_enabled ? day_hours(first_enabled) : Setting.hours_per_day
  end

  def full_day_name(day)
    I18n.t("date.day_names")[UserWorkingHours::DAY_ABBR_INDEX[day]]
  end
end

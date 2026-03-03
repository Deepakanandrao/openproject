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

require "spec_helper"

RSpec.describe "User non-working times", :js, with_flag: { user_working_times: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:managed_user) { create(:user) }

  let(:dialog_selector) { "##{Users::NonWorkingTimes::DialogComponent::DIALOG_ID}" }

  def visit_non_working_times(for_user: managed_user, year: 2026)
    visit user_non_working_times_path(for_user, year:)
  end

  def open_create_dialog
    click_on I18n.t(:button_add_non_working_time)
    expect(page).to have_css(dialog_selector)
  end

  def set_date_in_dialog(field_name, date)
    datepicker = Components::BasicDatepicker.new(dialog_selector)
    datepicker.open("input[name='non_working_time[#{field_name}]']")
    datepicker.set_date(date)
  end

  def submit_dialog
    within(dialog_selector) { click_on I18n.t(:button_confirm) }
    expect(page).to have_no_css(dialog_selector)
  end

  def expect_sidebar_entry(text)
    expect(page).to have_css("a[data-controller='async-dialog']", text:)
  end

  def expect_no_sidebar_entry(text)
    expect(page).to have_no_css("a[data-controller='async-dialog']", text:)
  end

  current_user { admin }

  describe "creating a non-working time" do
    before { visit_non_working_times }

    it "creates a single-day entry" do
      open_create_dialog

      set_date_in_dialog(:start_date, Date.new(2026, 3, 10))
      set_date_in_dialog(:end_date, Date.new(2026, 3, 10))

      submit_dialog

      expect_sidebar_entry("Mar 10")
      expect(managed_user.non_working_times.count).to eq(1)
    end

    it "creates a multi-day range and shows correct working day count" do
      open_create_dialog

      # Monday to Friday = 5 working days
      set_date_in_dialog(:start_date, Date.new(2026, 3, 9))
      set_date_in_dialog(:end_date, Date.new(2026, 3, 13))

      submit_dialog

      expect_sidebar_entry("5 working days")
    end

    it "shows a validation error when end date is before start date" do
      open_create_dialog

      set_date_in_dialog(:start_date, Date.new(2026, 3, 13))
      set_date_in_dialog(:end_date, Date.new(2026, 3, 9))

      within(dialog_selector) { click_on I18n.t(:button_confirm) }

      expect(page).to have_css(dialog_selector)
      within(dialog_selector) do
        expect(page).to have_text(I18n.t("activerecord.errors.models.user_non_working_time.attributes.end_date.not_before_start_date"))
      end
    end
  end

  describe "editing a non-working time" do
    shared_let(:non_working_time) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 3, 9),
                                     end_date: Date.new(2026, 3, 11))
    end

    before { visit_non_working_times }

    it "opens the edit dialog when clicking a sidebar entry" do
      find("a[data-controller='async-dialog']").click
      expect(page).to have_css(dialog_selector)

      within(dialog_selector) do
        expect(page).to have_field("non_working_time[start_date]", with: "2026-03-09")
        expect(page).to have_field("non_working_time[end_date]", with: "2026-03-11")
      end
    end

    it "saves updated dates" do
      find("a[data-controller='async-dialog']").click
      expect(page).to have_css(dialog_selector)

      set_date_in_dialog(:end_date, Date.new(2026, 3, 13))
      submit_dialog

      expect(non_working_time.reload.end_date).to eq(Date.new(2026, 3, 13))
    end
  end

  describe "deleting a non-working time" do
    shared_let(:non_working_time) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 4, 1),
                                     end_date: Date.new(2026, 4, 3))
    end

    before { visit_non_working_times }

    it "deletes the entry via the delete button in the edit dialog" do
      find("a[data-controller='async-dialog']").click
      expect(page).to have_css(dialog_selector)

      accept_confirm do
        within(dialog_selector) { click_on I18n.t(:button_delete) }
      end

      expect(page).to have_no_css(dialog_selector)
      expect(UserNonWorkingTime.exists?(non_working_time.id)).to be(false)
    end
  end

  describe "access control" do
    context "with manage_own_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_own_working_times]) }

      it "can view and manage their own non-working times" do
        visit user_non_working_times_path(current_user, year: 2026)

        expect(page).to have_button(I18n.t(:button_add_non_working_time))
      end

      it "is denied access to another user's non-working times" do
        visit_non_working_times
        expect(page).to have_text(I18n.t(:notice_not_authorized))
      end
    end

    context "with manage_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_working_times]) }

      shared_let(:other_user_nwt) do
        create(:user_non_working_time, user: managed_user,
                                       start_date: Date.new(2026, 5, 4),
                                       end_date: Date.new(2026, 5, 8))
      end

      before { visit_non_working_times }

      it "can view another user's non-working times page with the add button" do
        expect(page).to have_button(I18n.t(:button_add_non_working_time))
      end

      it "can open the edit dialog for another user's entry via the sidebar" do
        find("a[data-controller='async-dialog']").click
        expect(page).to have_css(dialog_selector)

        within(dialog_selector) do
          expect(page).to have_field("non_working_time[start_date]", with: "2026-05-04")
          expect(page).to have_button(I18n.t(:button_delete))
        end
      end

      it "can create a new entry for another user" do
        open_create_dialog

        set_date_in_dialog(:start_date, Date.new(2026, 6, 1))
        set_date_in_dialog(:end_date, Date.new(2026, 6, 5))

        submit_dialog

        expect(managed_user.non_working_times.count).to eq(2)
      end
    end

    context "with no working times permissions" do
      current_user { create(:user) }

      it "is denied access" do
        visit_non_working_times
        expect(page).to have_text(I18n.t(:notice_not_authorized))
      end
    end
  end
end

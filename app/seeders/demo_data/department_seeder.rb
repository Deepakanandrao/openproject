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

module DemoData
  class DepartmentSeeder < Seeder
    def seed_data!
      print_status "    ↳ Creating departments" do
        seed_departments
      end
    end

    def applicable?
      Group.organizational_units.none?
    end

    private

    def seed_departments
      seed_data.each("departments") do |department_data|
        department = create_department(department_data)
        seed_data.store_reference(department_data["reference"], department)
        seed_members(department, department_data)
      end
    end

    def create_department(department_data)
      Group.create!(
        lastname: department_data["name"],
        organizational_unit: true,
        parent_id: parent_id_for(department_data)
      )
    end

    def parent_id_for(department_data)
      reference = department_data["parent"]
      return if reference.blank?

      seed_data.find_reference(reference).id
    end

    def seed_members(department, department_data)
      users = Array(department_data["members"]).map do |member_data|
        user = create_user(member_data)
        seed_data.store_reference(member_data["reference"], user)
        user
      end

      return if users.empty?

      Groups::AddUsersService
        .new(department, current_user: admin_user)
        .call(ids: users.map(&:id), send_notifications: false)
        .on_failure { |result| raise result.message }
    end

    def create_user(member_data)
      firstname = member_data["firstname"]
      lastname = member_data["lastname"]
      login = "#{firstname}.#{lastname}".downcase

      User.new(
        login:,
        firstname:,
        lastname:,
        mail: "#{login}@example.com",
        status: User.statuses[:active],
        language: I18n.locale.to_s,
        password: login,
        force_password_change: false
      ).tap do |user|
        user.notification_settings.build(assignee: true, responsible: true, mentioned: true, watched: true)
        user.save!(validate: false)
      end
    end
  end
end

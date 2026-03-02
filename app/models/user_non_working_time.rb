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

class UserNonWorkingTime < ApplicationRecord
  belongs_to :user, inverse_of: :non_working_times

  validates :start_date, :end_date, presence: true
  validate :end_date_not_before_start_date
  validate :no_overlapping_ranges

  # Returns records whose range overlaps with the given year.
  scope :for_year, ->(year) {
    where("daterange(start_date, end_date, '[]') && daterange(?, ?, '[]')",
          Date.new(year, 1, 1), Date.new(year, 12, 31))
  }

  scope :for_user, ->(user) { where(user:) }

  scope :visible, ->(user = User.current) do
    if user.allowed_globally?(:manage_working_times)
      all
    else
      where(user:)
    end
  end

  def days
    start_date..end_date
  end

  def calendar_days_count
    (end_date - start_date).to_i + 1
  end

  def working_days
    working_wdays = Setting.working_days.map { |d| d % 7 }
    system_wide = NonWorkingDay.where(date: days).pluck(:date).to_set
    days.select { |date| working_wdays.include?(date.wday) && system_wide.exclude?(date) }
  end

  delegate :count, to: :working_days, prefix: true

  private

  def end_date_not_before_start_date
    return unless start_date.present? && end_date.present?

    errors.add(:end_date, :not_before_start_date) if end_date < start_date
  end

  def no_overlapping_ranges
    return unless start_date.present? && end_date.present? && user_id.present?

    errors.add(:start_date, :overlapping_range) if overlapping_range_exists?
  end

  def overlapping_range_exists?
    scope = self.class
                .where(user_id:)
                .where("daterange(start_date, end_date, '[]') && daterange(?, ?, '[]')",
                       start_date, end_date)
    scope = scope.where.not(id:) if persisted?
    scope.exists?
  end
end

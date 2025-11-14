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

module NumberFormatHelper
  def number_with_limit(number, opts = {})
    init_formatting_options(opts) => {
      delimiter:,
      separator:,
      digits:,
      precision:,
      length_limit:
    }

    string_number = number_with_precision(number, precision:, strip_insignificant_zeros: true)
    length = string_number.delete("#{delimiter}#{separator}").length

    scientific_notation_needed = length > length_limit ||
                                 integer_part_size(number) > digits ||
                                 (string_number == "0" && number != 0)

    if scientific_notation_needed
      format_scientific_notation(number, precision)
    else
      string_number
    end
  end

  private

  def integer_part_size(number) = number.round.to_s.size

  def format_scientific_notation(number, precision)
    exponent = number.to_d.exponent
    rounding_position = exponent - precision
    number.round(-1 * rounding_position).to_d.to_s("E")
  end

  def init_formatting_options(opts)
    {
      delimiter: I18n.t("number.format.delimiter"),
      separator: I18n.t("number.format.separator"),
      digits: opts[:digits] || 7,
      precision: opts[:precision] || 4,
      length_limit: opts[:length_limit] || 9
    }
  end
end

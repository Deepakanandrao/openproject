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

RSpec.describe NumberFormatHelper do
  describe "#number_with_limit" do
    [
      { input: 10, opts: {}, result: "10" },
      { input: 10.0, opts: {}, result: "10" },
      { input: 17203230.09932, opts: { length_limit: 8, digits: 8, precision: 3 }, result: "0.172e8" },
      { input: 17203230.09932, opts: { length_limit: 20, digits: 6, precision: 4 }, result: "0.172e8" },
      { input: 17203230.09932, opts: { length_limit: 20, digits: 6, precision: 5 }, result: "0.17203e8" },
      { input: 17203230.09932, opts: { length_limit: 20, digits: 10, precision: 3 }, result: "17203230.099" },
      { input: 8.402e-13, opts: { length_limit: 9, digits: 6, precision: 2 }, result: "0.84e-12" },
      { input: 8.402e-13, opts: { length_limit: 20, digits: 6, precision: 20 }, result: "0.0000000000008402" },
      { input: 8.402e-13, opts: { length_limit: 9, digits: 6, precision: 4 }, result: "0.8402e-12" }
    ].each do |test_case|
      test_case => { input:, opts:, result: }

      it "renders #{input} with #{opts} as #{result}" do
        expect(number_with_limit(input, opts)).to eq(result)
      end
    end
  end
end

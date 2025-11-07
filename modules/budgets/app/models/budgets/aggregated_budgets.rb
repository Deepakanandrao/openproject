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

module Budgets
  class AggregatedBudgets
    include Budgets::ProjectAggregation

    def initialize(project:, current_user: User.current)
      @project = project
      @current_user = current_user
    end

    def budget_count
      budgets.count
    end

    def budgeted_base
      budgets.sum(:base_amount)
    end

    def budgeted_material
      material_budget_items.sum(:amount)
    end

    def budgeted_material_by_type
      material_budget_items_by_type.sum("material_budget_items.amount")
    end

    def budgeted_labor
      labor_budget_items.sum(:amount)
    end

    def budgeted_total
      budgeted_base + budgeted_material + budgeted_labor
    end

    def has_budgets?
      budget_count.positive?
    end

    private

    def budgets
      Budget
        .joins(:project)
        .merge(applicable_projects)
        .visible(current_user)
    end

    def material_budget_items
      MaterialBudgetItem
        .joins(budget: :project)
        .merge(applicable_projects)
        .visible(current_user)
    end

    def material_budget_items_by_type
      CostType
        .left_joins(material_budget_items: { budget: :project })
        .merge(applicable_projects)
        .merge(MaterialBudgetItem.visible(current_user))
        .group(:name)
        .order(name: :asc)
    end

    def labor_budget_items
      LaborBudgetItem
        .joins(budget: :project)
        .merge(applicable_projects)
        .visible(current_user)
    end
  end
end

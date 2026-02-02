# frozen_string_literal: true

class ChangeJiraImportsProjectsToJsonb < ActiveRecord::Migration[8.0]
  def change
    change_table :jira_imports, bulk: true do |t|
      t.remove :projects, type: :string, array: true, default: []
      t.column :projects, :jsonb, default: []
    end
  end
end

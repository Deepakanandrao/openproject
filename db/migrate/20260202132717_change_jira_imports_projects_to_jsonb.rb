# frozen_string_literal: true

class ChangeJiraImportsProjectsToJsonb < ActiveRecord::Migration[8.0]
  def change
    remove_column :jira_imports, :projects, :string, array: true, default: []
    add_column :jira_imports, :projects, :jsonb, default: []
  end
end

class JiraProject < ApplicationRecord
  def to_op_attributes
    {
      name: payload["name"],
      identifier: payload["key"].downcase,
      parent_id: "",
      workspace_type: "project"
    }
  end
end

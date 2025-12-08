class OpenProjectJiraReference < ApplicationRecord
  def model
    op_entity_table.constantize.find(op_entity_id)
  end
end

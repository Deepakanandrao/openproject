# frozen_string_literal: true

class AddParticipationStatusForMeetingParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :meeting_participants, :participation_status, :string, null: true
  end
end

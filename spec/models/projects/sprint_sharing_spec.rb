# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::SprintSharing do
  let(:project) { create(:project) }

  describe "SPRINT_SHARING_OPTIONS" do
    it "defines all supported sprint sharing options" do
      expect(described_class::SPRINT_SHARING_OPTIONS).to match_array(
        %w[share_all_projects share_subprojects no_sharing receive_shared]
      )
    end

    it "is exposed on Project" do
      expect(Project::SPRINT_SHARING_OPTIONS).to eq(described_class::SPRINT_SHARING_OPTIONS)
    end
  end

  describe "#sprint_sharing" do
    it "defaults to no_sharing" do
      expect(project.sprint_sharing).to eq("no_sharing")
    end

    it "persists configured values" do
      project.update!(sprint_sharing: "share_subprojects")

      expect(project.reload.sprint_sharing).to eq("share_subprojects")
    end
  end
end

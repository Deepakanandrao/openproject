# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Projects::BacklogSettingsContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project) }
  let(:contract) { described_class.new(project, current_user) }
  let(:current_user) { build_stubbed(:user) }
  let(:can_share_sprint) { true }

  before do
    allow(current_user)
      .to receive(:allowed_in_project?)
      .with(:share_sprint, project)
      .and_return(can_share_sprint)
  end

  it_behaves_like "contract is valid"

  context "when sprint_sharing is changed" do
    before do
      project.sprint_sharing = sprint_sharing
    end

    context "with a supported sprint sharing value" do
      let(:sprint_sharing) { "share_subprojects" }

      context "when user can share sprint" do
        it_behaves_like "contract is valid"
      end

      context "when user cannot share sprint" do
        let(:can_share_sprint) { false }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end
    end

    context "with an unsupported sprint sharing value" do
      let(:sprint_sharing) { "invalid_option" }

      it_behaves_like "contract is invalid", sprint_sharing: :inclusion
    end
  end

  describe "#writable_attributes" do
    it "only allows sprint_sharing to be written" do
      expect(contract.writable_attributes).to include("sprint_sharing")
      expect(contract.writable_attributes).not_to include("settings")
      expect(contract.writable_attributes).not_to include("deactivate_work_package_attachments")
    end
  end
end

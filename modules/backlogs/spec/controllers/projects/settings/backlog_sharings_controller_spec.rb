# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Settings::BacklogSharingsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  before do
    allow(controller).to receive(:set_localization)
  end

  describe "PATCH #update" do
    let(:project) { build_stubbed(:project, sprint_sharing: "no_sharing") }

    before do
      visible_relation = instance_double(ActiveRecord::Relation)
      allow(Project).to receive(:visible).and_return(visible_relation)
      allow(visible_relation).to receive(:find).with(project.identifier).and_return(project)
    end

    context "when service call succeeds" do
      let(:service_result) { ServiceResult.success(result: project) }
      let(:update_service) { instance_double(Projects::UpdateService, call: service_result) }

      before do
        allow(Projects::UpdateService)
          .to receive(:new)
          .with(model: project, user:, contract_class: Projects::BacklogSettingsContract)
          .and_return(update_service)
      end

      it "updates sprint sharing and redirects to show", :aggregate_failures do
        patch :update, params: {
          project_id: project.identifier,
          project: {
            sprint_sharing: "share_subprojects",
            name: "must_be_ignored"
          }
        }

        expect(update_service).to have_received(:call).with(
          ActionController::Parameters.new("sprint_sharing" => "share_subprojects").permit!
        )
        expect(response).to redirect_to(project_settings_backlog_sharing_path(project))
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
      end
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(result: project, message: "invalid setting") }
      let(:update_service) { instance_double(Projects::UpdateService, call: service_result) }

      before do
        allow(Projects::UpdateService)
          .to receive(:new)
          .with(model: project, user:, contract_class: Projects::BacklogSettingsContract)
          .and_return(update_service)
      end

      it "renders show with an error", :aggregate_failures do
        patch :update, params: {
          project_id: project.identifier,
          project: {
            sprint_sharing: "invalid_option"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("projects/settings/backlog_sharings/show")
        expect(flash[:error]).to eq I18n.t(:notice_unsuccessful_update_with_reason, reason: "invalid setting")
      end
    end
  end
end

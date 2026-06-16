# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User avatar management", :js do
  include Rails.application.routes.url_helpers

  let(:image_base_path) { File.expand_path("#{File.dirname(__FILE__)}/../fixtures/") }
  let(:avatar_management_path) { edit_user_path(target_user) }

  let(:enable_gravatars) { false }
  let(:enable_local_avatars) { false }
  let(:plugin_settings) do
    {
      "enable_gravatars" => enable_gravatars,
      "enable_local_avatars" => enable_local_avatars
    }
  end

  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_avatars)
      .and_return(plugin_settings)
  end

  context "when user is admin" do
    let(:user) { create(:admin) }
    let(:target_user) { create(:user) }

    describe "only gravatars enabled" do
      let(:enable_gravatars) { true }

      it "shows the avatar section with the Gravatar hint but no upload field" do
        visit avatar_management_path

        expect(page).to have_css("h2", text: "Avatar")
        expect(page).to have_css(".avatars--current-avatar")
        expect(page).to have_css(".avatars--description", text: "Gravatar")
        expect(page).to have_no_field("avatar_file_input")
      end
    end

    describe "only local avatars enabled" do
      let(:enable_local_avatars) { true }

      it "exposes the avatar as an upload trigger and validates the file format" do
        visit avatar_management_path
        expect(page).to have_css("h2", text: "Avatar")
        expect(page).to have_css(".avatars--upload-trigger")

        # Gravatar hint is not rendered
        expect(page).to have_no_link("gravatar.com")

        # The upload component is active on this tab and rejects invalid files
        attach_file("avatar_file_input",
                    UploadedFile.load_from(File.join(image_base_path, "invalid.txt")).path,
                    make_visible: true)

        expect(page).to have_css(".avatars--error-pane", text: "Allowed formats are jpg, png, gif")
      end

      it "offers to delete an existing custom avatar" do
        target_user.attachments = [build(:avatar_attachment, author: target_user)]

        visit avatar_management_path

        accept_alert do
          find_test_selector("avatar-delete-link").click
        end

        expect(page).to have_no_test_selector("avatar-delete-link", wait: 20)
      end
    end

    describe "both gravatars and local avatars enabled" do
      let(:enable_gravatars) { true }
      let(:enable_local_avatars) { true }

      it "renders the Gravatar hint and the upload trigger in a single section" do
        visit avatar_management_path

        expect(page).to have_css("h2", text: "Avatar")
        expect(page).to have_css(".avatars--description", text: "Gravatar")
        expect(page).to have_css(".avatars--upload-trigger")
      end
    end

    describe "none enabled" do
      it "does not render the avatar section" do
        visit avatar_management_path
        expect(page).to have_button(I18n.t(:button_save))
        expect(page).to have_no_css("h2", text: "Avatar")
      end
    end
  end

  context "when user is self" do
    let(:user) { create(:user) }
    let(:target_user) { user }

    it "forbids the user to access" do
      visit edit_user_path(target_user)
      expect(page).to have_text("[Error 403]")
    end
  end

  context "when user is another user" do
    let(:target_user) { create(:user) }
    let(:user) { create(:user) }

    it "forbids the user to access" do
      visit edit_user_path(target_user)
      expect(page).to have_text("[Error 403]")
    end
  end
end

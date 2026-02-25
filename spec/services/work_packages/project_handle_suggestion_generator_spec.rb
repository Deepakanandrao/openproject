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

require "rails_helper"

RSpec.describe WorkPackages::ProjectHandleSuggestionGenerator do
  subject(:generator) { described_class.new }

  # Access private methods for unit testing the algorithm
  let(:private_gen) { described_class.new }

  describe ".call" do
    context "when there are no problematic project identifiers" do
      before do
        allow(Project).to receive(:all).and_return([
                                                     instance_double(Project, identifier: "valid", name: "Valid Project")
                                                   ])
      end

      it "returns an empty array" do
        expect(described_class.call).to be_empty
      end
    end

    context "when projects have identifiers that are too long" do
      let(:project) { instance_double(Project, identifier: "verylongidentifier", name: "Very Long Identifier") }

      before do
        allow(Project).to receive(:all).and_return([project])
      end

      it "returns a suggestion entry for the project" do
        result = described_class.call
        expect(result.size).to eq(1)
        expect(result.first[:project]).to eq(project)
        expect(result.first[:current_identifier]).to eq("verylongidentifier")
        expect(result.first[:error_reason]).to eq(:too_long)
        expect(result.first[:suggested_handle]).to be_present
        expect(result.first[:suggested_handle].length).to be <= 10
      end
    end

    context "when projects have identifiers with special characters" do
      let(:project) { instance_double(Project, identifier: "fly-sky", name: "Fly Sky") }

      before do
        allow(Project).to receive(:all).and_return([project])
      end

      it "returns a suggestion entry with error_reason :special_characters" do
        result = described_class.call
        expect(result.size).to eq(1)
        expect(result.first[:error_reason]).to eq(:special_characters)
      end
    end

    context "when multiple projects would generate conflicting handles" do
      let(:project_sc1) { instance_double(Project, identifier: "sc-app", name: "Stream Communicator") }
      let(:project_sc2) { instance_double(Project, identifier: "stream-channel", name: "Stream Channel") }

      before do
        allow(Project).to receive(:all).and_return([project_sc1, project_sc2])
      end

      it "generates unique handles for each project" do
        result = described_class.call
        handles = result.pluck(:suggested_handle)
        expect(handles.uniq.size).to eq(handles.size)
      end

      it "appends a numeric suffix to resolve conflicts" do
        result = described_class.call
        handles = result.pluck(:suggested_handle)
        # One will be "SC" and the other "SC2"
        expect(handles).to include("SC")
        expect(handles.any? { |h| h.match?(/\ASC\d+\z/) }).to be true
      end
    end

    context "with a mix of valid and problematic identifiers" do
      let(:valid_project) { instance_double(Project, identifier: "valid", name: "Valid") }
      let(:bad_project)   { instance_double(Project, identifier: "too-long-id", name: "Too Long Id") }

      before do
        allow(Project).to receive(:all).and_return([valid_project, bad_project])
      end

      it "only includes problematic projects in the result" do
        result = described_class.call
        expect(result.size).to eq(1)
        expect(result.first[:project]).to eq(bad_project)
      end
    end
  end

  describe "handle generation from project name" do
    {
      "Flight Planning Algorithm" => "FPA",
      "Fly & Sky" => "FS",
      "Social media marketing" => "SMM",
      "Arcanos Mobile Web App" => "AMWA",
      "Flight Planning Training" => "FPT",
      "A B C D E F G H I J K" => "ABCDEFGHIJ"
    }.each do |project_name, expected_handle|
      it "generates '#{expected_handle}' from '#{project_name}'" do
        project = instance_double(Project, identifier: "bad-id", name: project_name)
        allow(Project).to receive(:all).and_return([project])
        result = described_class.call
        expect(result.first[:suggested_handle]).to eq(expected_handle)
      end
    end
  end

  describe "problematic identifier detection" do
    valid_identifiers = %w[valid VALID123 abc arcanosweb]
    problematic_identifiers = ["verylongidentifier", "12345678901", "arcanos-web", "fly_sky", "fly&sky"]

    valid_identifiers.each do |identifier|
      it "does not flag '#{identifier}' as problematic" do
        project = instance_double(Project, identifier:, name: "Test Project")
        allow(Project).to receive(:all).and_return([project])
        expect(described_class.call).to be_empty
      end
    end

    problematic_identifiers.each do |identifier|
      it "flags '#{identifier}' as problematic" do
        project = instance_double(Project, identifier:, name: "Test Project")
        allow(Project).to receive(:all).and_return([project])
        expect(described_class.call).not_to be_empty
      end
    end
  end

  describe "error reason assignment" do
    context "when identifier is too long" do
      it "assigns :too_long" do
        project = instance_double(Project, identifier: "verylongidentifier", name: "Test")
        allow(Project).to receive(:all).and_return([project])
        expect(described_class.call.first[:error_reason]).to eq(:too_long)
      end
    end

    context "when identifier contains special characters" do
      it "assigns :special_characters" do
        project = instance_double(Project, identifier: "my-project", name: "Test")
        allow(Project).to receive(:all).and_return([project])
        expect(described_class.call.first[:error_reason]).to eq(:special_characters)
      end
    end

    context "when identifier is both too long and has special chars" do
      it "assigns :too_long (length takes priority)" do
        project = instance_double(Project, identifier: "my-very-long-identifier", name: "Test")
        allow(Project).to receive(:all).and_return([project])
        expect(described_class.call.first[:error_reason]).to eq(:too_long)
      end
    end
  end
end

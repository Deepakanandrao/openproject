# frozen_string_literal: true

Rails.application.routes.draw do
  constraints(project_id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+"), format: :html) do
    scope "projects/:project_id", as: "project" do
      scope module: "overviews" do
        resource :overview, path: "/", only: [:show]

        controller :overviews do
          get "project_custom_fields_sidebar" => :project_custom_fields_sidebar, as: :custom_fields_sidebar
          get "project_life_cycle_sidebar" => :project_life_cycle_sidebar, as: :life_cycle_sidebar

          get "project_custom_field_section_dialog/:section_id" => :project_custom_field_section_dialog,
              as: :custom_field_section_dialog
          put "project_update_custom_values/:section_id" => :project_update_custom_values, as: :update_custom_values
        end

        namespace :widgets do
          resource :project_status, only: %i[show update]
        end
      end
    end
  end

  resources :project_phases, controller: "overviews/project_phases", only: %i[edit update] do
    member do
      put :preview
    end
  end
end

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace "ldap_departments" do
    resources :synchronized_trees,
              param: :tree_id do
      member do
        # Synchronize the organizational unit structure and members of a single tree
        post "synchronize"
      end
    end

    resources :synchronized_departments,
              param: :department_id,
              only: %i(destroy)
  end
end

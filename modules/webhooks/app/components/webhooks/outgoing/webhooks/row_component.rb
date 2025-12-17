module ::Webhooks
  module Outgoing
    module Webhooks
      class RowComponent < ::RowComponent
        property :description

        delegate :event_names, to: :webhook

        def webhook
          model
        end

        def name
          link_to webhook.name,
                  { controller: table.target_controller, action: :show, webhook_id: webhook.id }
        end

        def enabled
          if webhook.enabled?
            helpers.op_icon "icon-yes"
          end
        end

        def events
          return t(:"webhooks.outgoing.label_x_event_resources", count: 0) if event_names.empty?

          event_names
            .filter_map { OpenProject::Webhooks::EventResources.lookup_resource_name(it) }
            .uniq
            .join(t(:"support.array.words_connector", default: ", "))
        end

        def selected_projects
          return t(:"webhooks.outgoing.form.project_ids.all") if webhook.all_projects?

          t(:label_x_projects, count: webhook.projects.size)
        end

        def row_css_class
          [
            "webhooks--outgoing-webhook-row",
            "webhooks--outgoing-webhook-row-#{model.id}"
          ].join(" ")
        end

        ###

        def button_links
          [edit_link, delete_link]
        end

        def edit_link
          link_to(
            helpers.op_icon("icon icon-edit button--link"),
            { controller: table.target_controller, action: :edit, webhook_id: webhook.id },
            title: t(:button_edit)
          )
        end

        def delete_link
          link_to(
            helpers.op_icon("icon icon-delete button--link"),
            { controller: table.target_controller, action: :destroy, webhook_id: webhook.id },
            data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
            title: t(:button_delete)
          )
        end
      end
    end
  end
end

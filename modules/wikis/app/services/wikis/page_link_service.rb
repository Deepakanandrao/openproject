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

module Wikis
  class PageLinkService
    def count(linkable)
      # Incomplete implementation until connection to Wikis API is done to fetch relation wiki page links
      # from external providers.
      # TODO: Replace with complete implementation

      Wikis::PageLink.joins(:provider)
                     .merge(Wikis::Provider.enabled)
                     .where(linkable:)
                     .count
    end

    def relation_page_links_for(provider:, linkable:)
      provider.page_links
              .merge(RelationPageLink.all)
              .where(linkable:)
              .order(created_at: :desc)
              .map { PageLinkViewModel.from_page_link(page_link: it, title_service: page_title_service) }
    end

    def inline_page_links_for(linkable:)
      InlinePageLink.where(linkable:)
                    .order(created_at: :desc)
                    .map { PageLinkViewModel.from_page_link(page_link: it, title_service: page_title_service) }
    end

    def referencing_wiki_pages_for(linkable:)
      # TODO: iterate over all providers and fetch mentions of this linkable

      if linkable.id % 2 == 0
        return [
          PageLinkViewModel.new(
            page_identifier: "42",
            provider: XWikiProvider.enabled.first,
            title: "I come from the wiki down under",
            href: "#"
          )
        ]
      end

      []
    end

    private

    def page_title_service
      @page_title_service ||= PageTitleService.new
    end
  end
end

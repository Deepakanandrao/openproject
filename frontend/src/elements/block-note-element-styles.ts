/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

/**
 * Shadow DOM styles for BlockNote editor
 *
 * Note: These styles are kept in a TypeScript constant to avoid build configuration complexity (for now).
 *
 * Stylesheet contains:
 * - https://github.com/opf/primer_view_components/blob/main/app/components/primer/alpha/skeleton_box.pcss
 *
 */
export default `
.block-note-editor-container {
  align-items: center;
  display: flex;
  flex-direction: column-reverse;
  gap: 10px;
  height: 100%;
  max-width: none;
  padding: 0;
}

.block-note-editor-container > .bn-editor {
  height: 100%;
  max-width: 800px;
  min-height: 80vh;
  overflow: auto;
  width: 100%;
  background-color: transparent;
  padding-top: 10px;
  padding-inline: 0;
}

@keyframes shimmer {
  from {
    mask-position: 200%;
  }

  to {
    mask-position: 0%;
  }
}

.mb-3 {
  margin-bottom: var(--base-size-16, 16px);
}

.SkeletonBox {
  display: block;
  height: 1rem;
  background-color: var(--bgColor-muted);
  border-radius: var(--borderRadius-small);
  animation: shimmer;

  @media (prefers-reduced-motion: no-preference) {
    mask-image: linear-gradient(75deg, #000 30%, rgb(0, 0, 0, 0.65) 80%);
    mask-size: 200%;
    animation: shimmer;
    animation-duration: 1s;
    animation-iteration-count: infinite;
  }

  @media (forced-colors: active) {
    outline: 1px solid transparent;
    outline-offset: -1px;
  }
}
`;

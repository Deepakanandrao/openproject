//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { vi } from 'vitest';
import { ViewPortService } from './view-port-service';

// isMobile() compares against window.innerWidth, so pick a breakpoint either
// side of the test window to force one layout or the other.
function serviceForViewport(mobile:boolean):ViewPortService {
  const breakpoint = mobile ? window.innerWidth + 1 : 0;
  return new ViewPortService('notifications', 'work_packages/details', breakpoint);
}

describe('ViewPortService#anchorScrollOffset', () => {
  let contentBody:HTMLElement;
  let tabContent:HTMLElement;

  beforeEach(() => {
    contentBody = document.createElement('div'); // mobile scroll container
    contentBody.id = 'content-body';
    document.body.appendChild(contentBody);

    tabContent = document.createElement('div'); // desktop scroll container
    tabContent.className = 'tabcontent';
    document.body.appendChild(tabContent);
  });

  afterEach(() => {
    contentBody.remove();
    tabContent.remove();
    vi.restoreAllMocks();
  });

  // Pins a header to the top of the scroll container and makes it the only box
  // the layout probe finds there. `reach` is how far it extends below the
  // container top.
  function pinHeader(container:HTMLElement, reach:number) {
    container.getBoundingClientRect = () => ({ top: 0, left: 0 }) as DOMRect;
    const header = document.createElement('div');
    header.style.position = 'sticky';
    container.appendChild(header);
    header.getBoundingClientRect = () => ({ bottom: reach }) as DOMRect;
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([header]);
  }

  it('seats the comment below a header pinned over the scroll container, plus a gap', () => {
    pinHeader(contentBody, 185);

    // 185 (measured toolbar) + 16 (gap)
    expect(serviceForViewport(true).anchorScrollOffset()).toBe(201);
  });

  it('uses just the gap when nothing is pinned over the container', () => {
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([]);

    expect(serviceForViewport(true).anchorScrollOffset()).toBe(16);
  });

  it('seats the comment a small gap below the top on desktop, showing only the stem', () => {
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([]);

    // .tabcontent has nothing pinned over it, so the offset is just the gap; a
    // large offset here exposed the bottom of the preceding comment.
    expect(serviceForViewport(false).anchorScrollOffset()).toBe(16);
  });
});

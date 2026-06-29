/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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

import { vi } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

// Stub FullCalendar so the controller mounts without a real calendar (which
// would measure the DOM and fetch the feeds). We only exercise the reload
// wiring, so a calendar exposing the refetch methods is enough.
const calendar = vi.hoisted(() => ({
  render: vi.fn(),
  destroy: vi.fn(),
  refetchEvents: vi.fn(),
  refetchResources: vi.fn(),
}));

vi.mock('@fullcalendar/core', async (importOriginal) => ({
  ...await importOriginal<typeof import('@fullcalendar/core')>(),
  // A plain function so `new Calendar(...)` returns our stub; an arrow would
  // not be constructable and would leave the controller without a calendar.
  Calendar: vi.fn(function MockCalendar() { return calendar; }),
}));

const EVENT_NAME = 'op-dispatched:resource-allocations:changed';

describe('WorkPackageTimelineController', () => {
  let ctx:StimulusTestContext;

  const mountTimeline = async ():Promise<void> => {
    const { default: WorkPackageTimelineController } = await import('./work-package-timeline.controller');
    ctx = await setupStimulusTest({
      controllers: { 'resource-management--work-package-timeline': WorkPackageTimelineController },
    });

    const prefix = 'data-resource-management--work-package-timeline';
    ctx.appendHTML(`
      <div data-controller="resource-management--work-package-timeline"
           ${prefix}-resources-url-value="/resources"
           ${prefix}-events-url-value="/events"
           ${prefix}-locale-value="en"
           ${prefix}-first-day-value="1"
           ${prefix}-initial-date-value="2026-06-29"
           ${prefix}-initial-view-value="resourceTimelineDays"
           ${prefix}-new-allocation-url-value=""
           ${prefix}-reload-event-name-value="${EVENT_NAME}">
        <div ${prefix}-target="calendar"></div>
      </div>
    `);

    // connect() schedules the calendar init on the next animation frame.
    await ctx.nextFrame();
    await ctx.nextFrame();
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    ctx.dispose();
  });

  it('refetches both feeds when the allocation-changed event fires', async () => {
    await mountTimeline();

    document.dispatchEvent(new CustomEvent(EVENT_NAME));

    expect(calendar.refetchResources).toHaveBeenCalledTimes(1);
    expect(calendar.refetchEvents).toHaveBeenCalledTimes(1);
  });

  it('stops refetching once the controller disconnects', async () => {
    await mountTimeline();
    ctx.container.querySelector('[data-controller]')?.removeAttribute('data-controller');
    await ctx.nextFrame();

    document.dispatchEvent(new CustomEvent(EVENT_NAME));

    expect(calendar.refetchResources).not.toHaveBeenCalled();
    expect(calendar.refetchEvents).not.toHaveBeenCalled();
  });
});

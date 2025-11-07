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

import { ChartOptions, TooltipModel } from 'chart.js';
import { html, render } from 'lit-html';

export const chartFont:ChartOptions['font'] = {
  family:
    "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji'",
  size: 14,
};

export const chartLegend:ChartOptions['plugins'] = {
  legend: {
    position: 'bottom',
    labels: {
      boxWidth: 56,
      boxHeight: 20,
      padding: 16,
      font: { size: 14 },
    },
  },
};

export function renderChartTooltip<TType extends 'bar' | 'pie'>(context:{ chart:{ canvas:HTMLCanvasElement }, tooltip:TooltipModel<TType> }) {
  const tooltipModel = context.tooltip;
  const popoverHtml = html`
  <div class="Popover" id="chartjs-tooltip">
    <div class="Box Popover-message Popover-message--left-top ml-2 mx-auto p-2 text-left text-small">
      <strong>${tooltipModel.title}</strong>
      <ul class="list-style-none ml-0">
        ${tooltipModel.body.map((item) => item.lines).map((body) => {
          return html`<li>${body}</li>`;
        })}
      </ul>
    </div>
  </div>`;

  render(popoverHtml, document.body);

  const tooltipEl = document.getElementById('chartjs-tooltip')!;

  if (tooltipModel.opacity === 0) {
    tooltipEl.style.opacity = '0';
    return;
  }

  const position = context.chart.canvas.getBoundingClientRect();

  tooltipEl.style.opacity = '1';
  tooltipEl.style.position = 'absolute';
  tooltipEl.style.left = position.left + window.pageXOffset + tooltipModel.caretX + 'px';
  tooltipEl.style.top = position.top + window.pageYOffset + tooltipModel.caretY + 'px';
  tooltipEl.style.pointerEvents = 'none';
}

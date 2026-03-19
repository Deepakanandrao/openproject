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

import {ApplicationController, useDebounce} from 'stimulus-use';

const ALLOWED_CHARS:Record<string, RegExp> = {
  semantic: /[^A-Z0-9_]/g,
  legacy: /[^a-z0-9\-_]/g,
};

export default class extends ApplicationController {
  static debounces = ['fetchSuggestion'];
  static targets = ['name', 'identifier'];

  static values = {
    url: String,
    debounce: {type: Number, default: 300},
    mode: {type: String, default: 'legacy'},
    setNameFirst: {type: String, default: ''},
  };

  declare urlValue:string;
  declare debounceValue:number;
  declare modeValue:string;
  declare setNameFirstValue:string;

  declare readonly nameTarget:HTMLInputElement;
  declare readonly identifierTarget:HTMLInputElement;
  declare readonly hasNameTarget:boolean;
  declare readonly hasIdentifierTarget:boolean;

  private handleBlur:((event:Event) => void) | null = null;
  private handleInput:((event:Event) => void) | null = null;

  connect():void {
    if (!this.hasNameTarget || !this.hasIdentifierTarget) return;

    this.handleInput = () => this.filterInput();
    this.identifierTarget.addEventListener('input', this.handleInput);

    if (this.urlValue) {
      if (!this.identifierTarget.value) {
        this.identifierTarget.placeholder = this.setNameFirstValue;
        this.identifierTarget.readOnly = true;
      }

      useDebounce(this, { wait: this.debounceValue });

      this.handleBlur = () => {
        const name = this.nameTarget.value.trim();
        if (name) void this.fetchSuggestion(name);
      };

      this.nameTarget.addEventListener('blur', this.handleBlur);
    }
  }

  disconnect():void {
    if (this.hasNameTarget && this.handleBlur) {
      this.nameTarget.removeEventListener('blur', this.handleBlur);
    }
    if (this.hasIdentifierTarget && this.handleInput) {
      this.identifierTarget.removeEventListener('input', this.handleInput);
    }
  }

  private filterInput():void {
    const pattern = ALLOWED_CHARS[this.modeValue] ?? ALLOWED_CHARS.legacy;
    const current = this.identifierTarget.value;
    const filtered = current.replace(pattern, '');

    if (filtered !== current) {
      const pos = this.identifierTarget.selectionStart ?? filtered.length;
      this.identifierTarget.value = filtered;
      const newPos = Math.min(pos, filtered.length);
      this.identifierTarget.setSelectionRange(newPos, newPos);
    }
  }

  private async fetchSuggestion(name:string):Promise<void> {
    if (!this.urlValue) return;

    this.identifierTarget.readOnly = true;
    this.identifierTarget.placeholder = I18n.t('js.projects.identifier_suggestion.loading');

    try {
      const url = `${this.urlValue}?name=${encodeURIComponent(name)}`;
      const response = await fetch(url, {headers: {Accept: 'application/json'}});

      if (!response.ok) return;

      const data = await response.json() as { identifier:string };
      this.identifierTarget.value = data.identifier;
    } finally {
      this.identifierTarget.readOnly = false;
      this.identifierTarget.placeholder = '';
    }
  }
}

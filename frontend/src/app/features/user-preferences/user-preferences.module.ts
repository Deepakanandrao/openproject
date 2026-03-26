import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { OpSharedModule } from 'core-app/shared/shared.module';
import {
  OpenprojectAutocompleterModule,
} from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import {
  NotificationsSettingsPageComponent,
} from 'core-app/features/user-preferences/notifications-settings/page/notifications-settings-page.component';
import {
  NotificationSettingInlineCreateComponent,
} from 'core-app/features/user-preferences/notifications-settings/inline-create/notification-setting-inline-create.component';
import {
  NotificationSettingsTableComponent,
} from './notifications-settings/table/notification-settings-table.component';
import { OpenprojectEnterpriseModule } from 'core-app/features/enterprise/openproject-enterprise.module';

@NgModule({
  providers: [
    UserPreferencesService,
  ],
  declarations: [
    NotificationsSettingsPageComponent,
    NotificationSettingInlineCreateComponent,
    NotificationSettingsTableComponent,
  ],
  imports: [
    CommonModule,
    OpSharedModule,
    OpenprojectAutocompleterModule,
    OpenprojectEnterpriseModule,
    FormsModule,
    ReactiveFormsModule,
  ],
})
export class OpenProjectMyAccountModule { }

import { I18n } from 'i18n-js';
import { registerDialogStreamAction } from 'core-turbo/dialog-stream-action';

registerDialogStreamAction();

// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
(window as any).global = window;

window.I18n = new I18n();

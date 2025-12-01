# frozen_string_literal: true

module FormFields
  module Primerized
    class BlockNoteEditorInput
      include Capybara::DSL

      def open_add_image_dialog
        editor = find_editor
        editor.send_keys("/image")
        editor.send_keys(:enter)
      end

      def open_command_dialog
        find_editor.send_keys("/")
      end

      def fill_in_with_content(content)
        editor = find_editor
        editor.send_keys(content)
      end

      def find_editor
        # page.find("op-block-note")

        element = page.evaluate_script <<~JS
          document.querySelector('op-block-note')
            .shadowRoot.querySelector('div[role="textbox"]')
        JS

        element.click
        element
      end
    end
  end
end

# def open_add_image_dialog
#   send_keys_to_editor("/image")
#   send_keys_to_editor(:enter)
# end

# def open_command_dialog
#   send_keys_to_editor("/")
# end

# def fill_in_with_content(content)
#   send_keys_to_editor(content)
# end

# private

# def send_keys_to_editor(text)
#   page.execute_script(<<~JS, text.to_s)
#     const host = document.querySelector('op-block-note');
#     const el = host.shadowRoot.querySelector('div[role="textbox"]');
#     el.focus();

#     const text = arguments[0];
#     if (text === 'enter') {
#       el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true }));
#       el.dispatchEvent(new KeyboardEvent('keypress', { key: 'Enter', code: 'Enter', bubbles: true }));
#       el.dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter', code: 'Enter', bubbles: true }));
#     } else {
#       document.execCommand('insertText', false, text);
#     }
#   JS
# end

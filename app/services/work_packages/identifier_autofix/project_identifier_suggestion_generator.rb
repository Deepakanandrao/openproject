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

module WorkPackages
  module IdentifierAutofix
    # Generates a short uppercase semantic identifier for each project.
    #
    # Identifiers are 2–10 uppercase alphanumeric characters that always start
    # with a letter.
    #
    # == Algorithm
    #
    # *Multi-word names* use word initials, truncated to +DEFAULT_IDENTIFIER_BASE_LENGTH+ (5):
    #   "Flight Planning Algorithm" → "FPA"
    #   "A B C D E F G H I J K"   → "ABCDE"
    #
    # *Single-word names* use the first +SINGLE_WORD_BASE_LENGTH+ (3) characters:
    #   "Banana" → "BAN"
    #
    # *Accented characters* are transliterated ("Cécile" → "CEC").
    # *Non-Latin scripts* that have no transliteration fall back to "PROJ".
    #
    # == Collision resolution
    #
    # When a candidate is already taken, the identifier is progressively widened
    # with more characters from the name, up to +MAX_IDENTIFIER_LENGTH+ (10):
    #
    #   Multi-word:  "SC" → "STC" → "STCO" → "STRCO" → … → "STREACOMMU"
    #   Single-word: "BAN" → "BANA" → "BANAN" → "BANANA"
    #   Initials:    "ABCDE" → "ABCDEF" → … → "ABCDEFGHIJ"
    #
    # If all expansion candidates are exhausted, a numeric suffix is appended
    # as a last resort ("GO" → "GO2").
    #
    class ProjectIdentifierSuggestionGenerator
      MAX_IDENTIFIER_LENGTH = 10
      DEFAULT_IDENTIFIER_BASE_LENGTH = 5
      MIN_IDENTIFIER_LENGTH = 2
      SINGLE_WORD_BASE_LENGTH = 3
      FALLBACK_IDENTIFIER = "PROJ"
      SUFFIX_LIMIT = 10_000

      def self.call(projects, reserved_identifiers: Set.new, in_use_identifiers: Set.new)
        new.call(projects, reserved_identifiers:, in_use_identifiers:)
      end

      # Returns a single suggested identifier string for the given project name.
      #
      def self.suggest_identifier(name, reserved_identifiers: Set.new, in_use_identifiers: Set.new)
        new.suggest_identifier(name, reserved_identifiers:, in_use_identifiers:)
      end

      def call(projects, reserved_identifiers:, in_use_identifiers:)
        generate_suggestions(projects, reserved_identifiers:, in_use_identifiers:)
      end

      def suggest_identifier(name, reserved_identifiers: Set.new, in_use_identifiers: Set.new)
        used = combined_identifiers(reserved_identifiers, in_use_identifiers)
        candidates = identifier_candidates(name)
        find_unique(candidates, used)
      end

      private

      def generate_suggestions(projects, reserved_identifiers:, in_use_identifiers:)
        used_identifiers = combined_identifiers(reserved_identifiers, in_use_identifiers)

        projects.map do |project|
          candidates = identifier_candidates(project.name)
          identifier = find_unique(candidates, used_identifiers)
          used_identifiers << identifier

          {
            project:,
            current_identifier: project.identifier,
            suggested_identifier: identifier
          }
        end
      end

      # Returns an ordered list of progressively longer identifier candidates
      # derived from the project name. The first unique candidate wins.
      def identifier_candidates(name)
        words = transliterated_words(name)
        return [FALLBACK_IDENTIFIER] if words.empty?

        candidates = words.size == 1 ? single_word_candidates(words.first) : multi_word_candidates(words)
        candidates = candidates.filter_map { ensure_starts_with_letter(it) }
        candidates = candidates.select { it.length >= MIN_IDENTIFIER_LENGTH }
        candidates.presence || [FALLBACK_IDENTIFIER]
      end

      # Splits a name into words and transliterates each, returning only words
      # that contain at least one ASCII-alphanumeric character.
      def transliterated_words(name)
        # Use POSIX [[:alpha:]] so accented letters (é, ñ, ü…) are kept inside
        # their word rather than treated as separators by the ASCII-only [a-zA-Z].
        raw_words = name.to_s.scan(/[[:alpha:][:digit:]]+/)
        raw_words.filter_map do |word|
          t = I18n.with_locale(:en) { I18n.transliterate(word) }
          clean = t.scan(/[A-Za-z0-9]/).join
          clean.presence
        end
      end

      # "Banana" → ["BAN", "BANA", "BANAN", "BANANA"]
      def single_word_candidates(word)
        chars = word.upcase
        max_len = [chars.length, MAX_IDENTIFIER_LENGTH].min
        return [] if max_len < MIN_IDENTIFIER_LENGTH

        start_len = SINGLE_WORD_BASE_LENGTH.clamp(MIN_IDENTIFIER_LENGTH, max_len)
        (start_len..max_len).map { |len| chars[0, len] }
      end

      # "Stream Communicator" → ["SC", "STC", "STCO", "STRCO", …]
      # "A B C D E F G H I J K" → ["ABCDE", "ABCDEF", …, "ABCDEFGHIJ"]
      #
      # Phase 1: Truncate initials to DEFAULT_IDENTIFIER_BASE_LENGTH, then
      #          progressively include more initials up to MAX_IDENTIFIER_LENGTH.
      # Phase 2: If still room, expand words beyond single chars.
      def multi_word_candidates(words)
        clean_words = words.map { |w| w.upcase.chars }
        candidates = initial_truncation_candidates(clean_words)

        return candidates if candidates.last&.length.to_i >= MAX_IDENTIFIER_LENGTH

        chars_per_word = clean_words.map { 1 }
        append_expansion_candidates(candidates, clean_words, chars_per_word)
        candidates
      end

      # Phase 1: progressively longer slices of the initials string,
      # starting at DEFAULT_IDENTIFIER_BASE_LENGTH.
      def initial_truncation_candidates(clean_words)
        initials = clean_words.map(&:first).join[0, MAX_IDENTIFIER_LENGTH]
        start = [DEFAULT_IDENTIFIER_BASE_LENGTH, initials.length].min
        (start..initials.length).map { |len| initials[0, len] }
      end

      # Phase 2: pull more characters from each word left-to-right.
      def append_expansion_candidates(candidates, clean_words, chars_per_word)
        expand_word_candidates(clean_words, chars_per_word).each do |c|
          candidates << c unless candidates.include?(c)
          break if c.length >= MAX_IDENTIFIER_LENGTH
        end
      end

      def expand_word_candidates(clean_words, chars_per_word)
        candidates = []

        loop do
          candidate = build_candidate(clean_words, chars_per_word)
          candidates << candidate unless candidates.include?(candidate)
          break if candidate.length >= MAX_IDENTIFIER_LENGTH

          expandable = clean_words.index.with_index { |cw, i| chars_per_word[i] < cw.length }
          break unless expandable

          chars_per_word[expandable] += 1
        end

        candidates
      end

      def build_candidate(clean_words, chars_per_word)
        clean_words.each_with_index.map { |cw, i| cw.first(chars_per_word[i]).join }.join[0, MAX_IDENTIFIER_LENGTH]
      end

      # Strips leading digits so identifiers always start with a letter.
      # Returns nil if nothing remains after stripping.
      def ensure_starts_with_letter(candidate)
        stripped = candidate.sub(/\A\d+/, "")
        stripped.presence
      end

      # Iterates through expansion candidates, then falls back to numeric suffix.
      def find_unique(candidates, used_identifiers)
        candidates.each do |candidate|
          return candidate unless used_identifiers.include?(candidate)
        end

        base = candidates.last || FALLBACK_IDENTIFIER
        numeric_suffix_fallback(base, used_identifiers)
      end

      def numeric_suffix_fallback(base, used_identifiers)
        counter = 2
        loop do
          raise "Could not find a unique identifier for base '#{base}' within #{SUFFIX_LIMIT} attempts" \
            if counter > SUFFIX_LIMIT

          suffix = counter.to_s
          candidate = "#{base[0, MAX_IDENTIFIER_LENGTH - suffix.length]}#{suffix}"
          return candidate unless used_identifiers.include?(candidate)

          counter += 1
        end
      end

      def combined_identifiers(*sets)
        sets.reduce(Set.new, :merge)
      end
    end
  end
end

# frozen_string_literal: true

require_relative "completions"

module TTY
  class Reader
    # Responsible for word completion
    #
    # @api private
    class Completer
      # The completion suggestions
      attr_reader :completions

      # The handler for finding word completion suggestions
      attr_accessor :handler

      # The suffix to add to suggested word completion
      attr_accessor :suffix

      # The word to complete
      attr_reader :word

      # Create a Completer instance
      #
      # @api private
      def initialize(handler: nil, suffix: "")
        @handler = handler
        @suffix = suffix
        @completions = Completions.new
        @show_initial = false
        @word = ""
      end

      # Find a suggestion to complete a word
      #
      # @param [Line] line
      #   the line to complete a word in
      #
      # @return [String, nil]
      #   the completed word or nil when no suggestion is found
      #
      # @api public
      def complete(line, initial: false)
        initial ? complete_initial(line) : complete_next(line)
      end

      # Find suggestions and complete the initial word
      #
      # @param [Line] line
      #   the line to complete a word in
      #
      # @return [String, nil]
      #   the completed word or nil when no suggestion is found
      #
      # @api public
      def complete_initial(line)
        @word = line.word_to_complete
        suggestions = handler.(word)
        completions.clear

        return if suggestions.empty?

        completions.concat(suggestions)
        completed_word = completions.get

        line.remove(word.length)
        line.insert(completed_word + suffix)

        completed_word
      end

      # Complete a word with the next suggestion from completions
      #
      # @param [Line] line
      #   the line to complete a word in
      #
      # @return [String, nil]
      #   the completed word or nil when no suggestion is found
      #
      # @api public
      def complete_next(line)
        return if completions.empty?

        previous_suggestion = completions.get
        if completions.last? && !@show_initial
          @show_initial = true
          completed_word = word
        else
          if @show_initial
            @show_initial = false
            previous_suggestion = word
          end
          completions.next
          completed_word = completions.get
        end

        length_to_remove = previous_suggestion.length
        length_to_remove += suffix.length if previous_suggestion != word

        line.remove(length_to_remove)
        line.insert("#{completed_word}#{suffix unless @show_initial}")

        completed_word
      end
    end # Completer
  end # Reader
end # TTY

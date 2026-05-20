require 'rouge'

module Rouge
  module Lexers
    class Hica < Rouge::RegexLexer
      title "hica"
      desc "The hica programming language (hica.dev)"
      tag 'hica'
      filenames '*.hc'
      mimetypes 'text/x-hica'

      KEYWORD_CONTROL = %w(
        if else match for in while loop repeat break continue return
      ).freeze

      KEYWORD_DECLARATION = %w(
        fun let var struct type extern
      ).freeze

      KEYWORD_IMPORT = %w(
        import from pub
      ).freeze

      KEYWORD_TEST = %w(
        test
      ).freeze

      BUILTIN_CONSTANTS = %w(
        true false None
      ).freeze

      BUILTIN_CONSTRUCTORS = %w(
        Some Ok Err
      ).freeze

      BUILTIN_TYPES = %w(
        int float bool string char list maybe result
      ).freeze

      state :root do
        # Line comments
        rule %r(//.*$), Comment::Single

        # Whitespace
        rule %r/\s+/, Text::Whitespace

        # Test block with string name
        rule %r/\b(test)\b/, Keyword, :test_name

        # Keywords
        rule %r/\b(#{KEYWORD_CONTROL.join('|')})\b/, Keyword
        rule %r/\b(#{KEYWORD_DECLARATION.join('|')})\b/, Keyword::Declaration
        rule %r/\b(#{KEYWORD_IMPORT.join('|')})\b/, Keyword::Namespace

        # Built-in constants
        rule %r/\b(#{BUILTIN_CONSTANTS.join('|')})\b/, Keyword::Constant

        # Built-in types
        rule %r/\b(#{BUILTIN_TYPES.join('|')})\b/, Keyword::Type

        # Built-in constructors
        rule %r/\b(#{BUILTIN_CONSTRUCTORS.join('|')})\b/, Name::Builtin

        # User-defined PascalCase constructors / type names
        rule %r/\b[A-Z][a-zA-Z0-9_]*\b/, Name::Class

        # Function declaration: fun name
        rule %r/(?<=\bfun\s)[a-z_][a-zA-Z0-9_]*/, Name::Function

        # Function call: name(
        rule %r/\b([a-z_][a-zA-Z0-9_]*)(\s*\()/ do
          groups Name::Function, Punctuation
        end

        # Numbers
        rule %r/\b0[xX][0-9a-fA-F_]+\b/, Num::Hex
        rule %r/\b0[bB][01_]+\b/, Num::Bin
        rule %r/\b[0-9][0-9_]*\.[0-9][0-9_]*\b/, Num::Float
        rule %r/\b[0-9][0-9_]*\b/, Num::Integer

        # Strings
        rule %r/"/, Str::Double, :string

        # Char literals
        rule %r/'[^']'/, Str::Char

        # Multi-char operators
        rule %r/\.\.\./, Operator
        rule %r/\.\.=/, Operator
        rule %r/\.\./,  Operator
        rule %r/\|>/,   Operator
        rule %r/=>/,    Operator
        rule %r/->/,    Operator
        rule %r/==|!=|<=|>=/, Operator
        rule %r/&&|\|\|/, Operator

        # Single-char operators
        rule %r/[+\-*\/%=<>!?|]/, Operator

        # Punctuation
        rule %r/[{}()\[\],;:.]/, Punctuation

        # Identifiers
        rule %r/[a-z_][a-zA-Z0-9_]*/, Name
      end

      state :string do
        rule %r/"/, Str::Double, :pop!
        rule %r/\\[nrtf0\\\/"'{}]/, Str::Escape
        rule %r/\{[^}]*\}/, Str::Interpol
        rule %r/[^"\\{]+/, Str::Double
      end

      state :test_name do
        rule %r/\s+/, Text::Whitespace
        rule %r/"[^"]*"/, Str::Double, :pop!
        rule %r//, Text, :pop!  # fallback if no string follows
      end
    end
  end
end

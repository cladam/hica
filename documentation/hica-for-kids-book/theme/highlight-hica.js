(function () {
  function registerhica() {
    if (!window.hljs) return;

    hljs.registerLanguage('hica', function (hljs) {
      return {
        name: 'hica',
        aliases: ['hc'],
        keywords: {
          keyword:
            'if else match for in while loop repeat break continue return ' +
            'fun let var struct type extern import from test',
          literal: 'true false None',
          built_in: 'Some Ok Err int float bool string char list maybe result',
          // pub as a separate class so themes can colour it differently
          'keyword-pub': 'pub',
        },
        contains: [
          // Line comments
          hljs.COMMENT('//', '$'),

          // Double-quoted strings with interpolation
          {
            className: 'string',
            begin: '"',
            end: '"',
            contains: [
              { className: 'subst',       begin: /\{/, end: /\}/ },
              { className: 'char.escape', begin: /\\[nrtf0\\"'{}]/ },
            ],
          },

          // Char literals
          { className: 'string', begin: /'[^']'/ },

          // Numbers
          { className: 'number', begin: /\b0[xX][0-9a-fA-F_]+/ },
          { className: 'number', begin: /\b0[bB][01_]+/ },
          { className: 'number', begin: /\b[0-9][0-9_]*\.[0-9][0-9_]*/ },
          { className: 'number', begin: /\b[0-9][0-9_]*/ },

          // Operators — full set matching Vim/tmLanguage
          { className: 'operator', begin: /\|>|=>|->|\.\.\.?|==|!=|<=|>=|&&|\|\||[?]/ },
          { className: 'operator', begin: /[+\-*\/%<>!|]/ },

          // Function declaration: "fun name" — highlight the name as a function
          {
            begin: /\bfun\s+/,
            end: /\b[a-z_][a-zA-Z0-9_]*/,
            returnBegin: false,
            contains: [
              {
                className: 'title.function',
                begin: /[a-z_][a-zA-Z0-9_]*/,
              },
            ],
          },

          // PascalCase type/constructor names
          { className: 'type', begin: /\b[A-Z][a-zA-Z0-9_]*/ },

          // Function call sites
          {
            className: 'title.function.invoke',
            begin: /\b[a-z_][a-zA-Z0-9_]*(?=\s*\()/,
          },
        ],
      };
    });

    // Use whichever highlight API this version of hljs exposes.
    // Note: mdBook's own highlightAll() fires first and prints "could not find
    // language 'hica'" warnings — those are harmless noise we cannot suppress.
    var highlightEl = hljs.highlightElement
      ? function (el) { hljs.highlightElement(el); }
      : function (el) { hljs.highlightBlock(el); };

    document.querySelectorAll('code.language-hica').forEach(highlightEl);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', registerhica);
  } else {
    registerhica();
  }
})();

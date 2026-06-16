const {
  useState,
  useEffect
} = React;
const Icon = ({
  name,
  size = 24,
  className = "",
  style = {}
}) => {
  useEffect(() => {
    if (window.lucide) window.lucide.createIcons();
  }, [name]);
  return /*#__PURE__*/React.createElement("i", {
    "data-lucide": name,
    className: className,
    style: {
      width: size,
      height: size,
      ...style
    }
  });
};
const App = () => {
  const theme = {
    indigo: '#4f46e5',
    cyan: '#0891b2',
    primary: '#1e293b',
    secondary: '#64748b',
    bgLight: '#f8fafc',
    border: '#e2e8f0',
    codeBg: '#f6f8fa',
    syntax: {
      keyword: '#7c3aed',
      builtin: '#0550ae',
      function: '#0891b2',
      string: '#16a34a',
      comment: '#94a3b8',
      punctuation: '#64748b'
    }
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "min-h-screen flex flex-col"
  }, /*#__PURE__*/React.createElement("header", {
    className: "relative pt-20 pb-20 overflow-hidden bg-white border-b border-[#f1f5f9]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex justify-center mb-8"
  }, /*#__PURE__*/React.createElement("img", {
    src: "assets/hica-logo2.png",
    alt: "hica Logo",
    className: "h-24 w-auto",
    onError: e => e.target.style.display = 'none'
  })), /*#__PURE__*/React.createElement("h1", {
    className: "text-4xl md:text-7xl font-extrabold tracking-tight text-[#1e293b] mb-6"
  }, "A ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.indigo
    }
  }, "statically typed"), ", expression-oriented language."), /*#__PURE__*/React.createElement("p", {
    className: "text-xl md:text-2xl text-[#64748b] max-w-3xl mx-auto mb-12 leading-relaxed font-medium"
  }, "Hindley-Milner inference. Compiled to ", /*#__PURE__*/React.createElement("strong", null, "C"), ", ", /*#__PURE__*/React.createElement("strong", null, "JS"), ", or ", /*#__PURE__*/React.createElement("strong", null, "WASM"), " through Koka. Perceus reference counting. Familiar syntax."), /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col sm:flex-row justify-center gap-4"
  }, /*#__PURE__*/React.createElement("a", {
    href: "https://www.hica.dev/docs/",
    className: "px-8 py-4 rounded-xl font-bold text-lg text-white shadow-lg transition-all flex items-center justify-center gap-2",
    style: {
      backgroundColor: theme.indigo
    }
  }, "Read the docs ", /*#__PURE__*/React.createElement(Icon, {
    name: "arrow-right",
    size: 20
  })), /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/cladam/hica",
    className: "bg-white text-[#1e293b] border-2 border-[#e2e8f0] px-8 py-4 rounded-xl font-bold text-lg hover:border-[#4f46e5]/30 transition-all flex items-center justify-center gap-2"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "github",
    size: 20
  }), " View on GitHub")))), /*#__PURE__*/React.createElement("section", {
    className: "py-12 bg-[#f8fafc]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-5xl mx-auto px-4 lg:px-0"
  }, /*#__PURE__*/React.createElement("div", {
    className: "bg-[#f6f8fa] rounded-2xl shadow-xl overflow-hidden border border-[#e2e8f0]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between px-6 py-4 bg-white/50 border-b border-[#e2e8f0]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex gap-2"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-3 h-3 rounded-full bg-slate-200"
  }), /*#__PURE__*/React.createElement("div", {
    className: "w-3 h-3 rounded-full bg-slate-200"
  }), /*#__PURE__*/React.createElement("div", {
    className: "w-3 h-3 rounded-full bg-slate-200"
  })), /*#__PURE__*/React.createElement("div", {
    className: "text-xs font-bold font-mono text-[#64748b] tracking-widest"
  }, "fizzbuzz.hc"), /*#__PURE__*/React.createElement("div", {
    className: "w-10"
  })), /*#__PURE__*/React.createElement("div", {
    className: "p-8 md:p-12 font-mono text-sm md:text-base leading-loose overflow-x-auto text-[#1e293b]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex gap-6"
  }, /*#__PURE__*/React.createElement("div", {
    className: "text-[#cbd5e1] select-none text-right w-8 border-r border-slate-200 pr-4"
  }, "1", /*#__PURE__*/React.createElement("br", null), "2", /*#__PURE__*/React.createElement("br", null), "3", /*#__PURE__*/React.createElement("br", null), "4", /*#__PURE__*/React.createElement("br", null), "5", /*#__PURE__*/React.createElement("br", null), "6", /*#__PURE__*/React.createElement("br", null), "7", /*#__PURE__*/React.createElement("br", null), "8", /*#__PURE__*/React.createElement("br", null), "9", /*#__PURE__*/React.createElement("br", null), "10", /*#__PURE__*/React.createElement("br", null), "11"), /*#__PURE__*/React.createElement("div", {
    className: "flex-1 whitespace-pre"
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "fun "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.function
    }
  }, "fizzbuzz"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "(n) =>"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "if "), /*#__PURE__*/React.createElement("span", null, "n % 15 == 0 "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "{", " "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.string
    }
  }, "\"fizzbuzz\""), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, " ", "}"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "else if "), /*#__PURE__*/React.createElement("span", null, "n % 3 == 0 "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "{", " "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.string
    }
  }, "\"fizz\""), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, " ", "}"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "else if "), /*#__PURE__*/React.createElement("span", null, "n % 5 == 0 "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "{", " "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.string
    }
  }, "\"buzz\""), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, " ", "}"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "else "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "{", " "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.string
    }
  }, "\"", '{', "n", '}', "\""), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, " ", "}"), "\n", "\n", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "fun "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.function
    }
  }, "main"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "() ", "{"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "for "), /*#__PURE__*/React.createElement("span", null, "i "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.keyword,
      fontWeight: 'bold'
    }
  }, "in "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.builtin
    }
  }, "1"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, ".."), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.builtin
    }
  }, "100"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, " ", "{}"), "\n", "    ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.function
    }
  }, "println"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "("), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.function
    }
  }, "fizzbuzz"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "(i))"), "\n", "  ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "}"), "\n", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.syntax.punctuation
    }
  }, "}")))), /*#__PURE__*/React.createElement("div", {
    className: "bg-white p-5 border-t border-[#e2e8f0] flex items-center gap-3"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-6 h-6 rounded-full flex items-center justify-center text-white",
    style: {
      backgroundColor: theme.indigo
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "check-circle-2",
    size: 14
  })), /*#__PURE__*/React.createElement("span", {
    className: "text-sm font-bold text-[#1e293b]"
  }, "Everything is an expression. ", /*#__PURE__*/React.createElement("code", {
    className: "font-mono text-sm px-1.5 py-0.5 bg-indigo-50 text-indigo-600 rounded"
  }, "if"), ", ", /*#__PURE__*/React.createElement("code", {
    className: "font-mono text-sm px-1.5 py-0.5 bg-indigo-50 text-indigo-600 rounded"
  }, "match"), ", and blocks all return values."))))), /*#__PURE__*/React.createElement("section", {
    className: "py-24 bg-white overflow-hidden"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"
  }, /*#__PURE__*/React.createElement("div", {
    className: "grid md:grid-cols-2 gap-16 items-center"
  }, /*#__PURE__*/React.createElement("div", {
    className: "relative"
  }, /*#__PURE__*/React.createElement("div", {
    className: "absolute -top-10 -left-10 w-32 h-32 opacity-10 bg-[#4f46e5] rounded-full blur-3xl"
  }), /*#__PURE__*/React.createElement("h2", {
    className: "text-4xl font-bold mb-6 text-[#1e293b]"
  }, "Why hica exists."), /*#__PURE__*/React.createElement("p", {
    className: "text-lg text-[#64748b] mb-6 leading-relaxed"
  }, "hica is a safe, expression-oriented, functional-flavored language with a gentle learning curve. Immutability by default, no null, errors as values — and type inference that gets out of your way."), /*#__PURE__*/React.createElement("div", {
    className: "bg-[#f8fafc] p-6 rounded-xl border-l-4 border-[#4f46e5] italic text-[#1e293b] font-medium mb-8"
  }, /*#__PURE__*/React.createElement("strong", null, "H"), "indley-milner ", /*#__PURE__*/React.createElement("strong", null, "I"), "nference ", /*#__PURE__*/React.createElement("strong", null, "C"), "ompiler with ", /*#__PURE__*/React.createElement("strong", null, "A"), "lgebraic effects"), /*#__PURE__*/React.createElement("p", {
    className: "text-[#64748b] leading-relaxed"
  }, "By targeting Koka, hica inherits Perceus reference counting, algebraic effects, and compilation to C without reinventing any of it.")), /*#__PURE__*/React.createElement("div", {
    className: "grid grid-cols-1 gap-6"
  }, [{
    title: "Expression-Oriented",
    desc: "if, match, and blocks all return values. No return keyword needed.",
    icon: "zap"
  }, {
    title: "Type Inference",
    desc: "Hindley-Milner inference catches errors at compile time. Annotations are optional.",
    icon: "shield-check"
  }, {
    title: "No GC",
    desc: "Perceus reference counting via Koka. Predictable performance.",
    icon: "cpu"
  }].map(item => /*#__PURE__*/React.createElement("div", {
    key: item.title,
    className: "bg-white p-6 rounded-2xl border border-[#e2e8f0] shadow-sm hover:shadow-md transition-shadow flex gap-4"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex-shrink-0 w-12 h-12 rounded-lg flex items-center justify-center",
    style: {
      backgroundColor: `${theme.indigo}10`,
      color: theme.indigo
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: item.icon,
    size: 24
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h3", {
    className: "font-bold text-[#1e293b] mb-1"
  }, item.title), /*#__PURE__*/React.createElement("p", {
    className: "text-sm text-[#64748b]"
  }, item.desc)))))))), /*#__PURE__*/React.createElement("section", {
    className: "py-24 bg-[#f8fafc] border-y border-[#e2e8f0]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"
  }, /*#__PURE__*/React.createElement("div", {
    className: "text-center mb-16"
  }, /*#__PURE__*/React.createElement("h2", {
    className: "text-4xl font-bold text-[#1e293b] mb-4"
  }, "Language Features"), /*#__PURE__*/React.createElement("p", {
    className: "text-xl text-[#64748b] font-medium max-w-2xl mx-auto"
  }, "What hica supports today.")), /*#__PURE__*/React.createElement("div", {
    className: "grid md:grid-cols-3 gap-8"
  }, [{
    icon: 'arrow-right',
    name: 'Arrow Syntax',
    desc: 'Expression-bodied functions with =>. Single expressions or block bodies.'
  }, {
    icon: 'git-branch',
    name: 'Pattern Matching',
    desc: 'Guards, or-patterns, range patterns, tuple destructuring, and exhaustiveness checking.'
  }, {
    icon: 'link',
    name: 'Pipe Operator',
    desc: 'Chain functions left-to-right with |>. Pairs well with map, filter, and fold.'
  }, {
    icon: 'box',
    name: 'Structs & Enums',
    desc: 'Define data with structs and algebraic enums. Pattern match on variants with exhaustiveness.'
  }, {
    icon: 'flask-conical',
    name: 'Built-in Testing',
    desc: 'test blocks, assert, and assert_eq built into the language. Run with hica test.'
  }, {
    icon: 'layers',
    name: 'Compiles to C',
    desc: 'Through Koka to native binaries, JavaScript, or WASM.'
  }].map(feature => /*#__PURE__*/React.createElement("div", {
    key: feature.name,
    className: "bg-white p-8 rounded-2xl shadow-sm border border-[#e2e8f0] hover:shadow-md transition-all"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-12 h-12 rounded-xl flex items-center justify-center mb-6",
    style: {
      backgroundColor: `${theme.indigo}15`,
      color: theme.indigo
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: feature.icon,
    size: 24
  })), /*#__PURE__*/React.createElement("h3", {
    className: "text-xl font-bold mb-3 text-[#1e293b]"
  }, feature.name), /*#__PURE__*/React.createElement("p", {
    className: "text-[#64748b] text-sm leading-relaxed font-medium"
  }, feature.desc)))))), /*#__PURE__*/React.createElement("section", {
    className: "py-24 bg-white"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center"
  }, /*#__PURE__*/React.createElement("h2", {
    className: "text-4xl font-bold mb-16 text-[#1e293b]"
  }, "The Compilation Pipeline."), /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col md:flex-row items-center justify-center gap-4"
  }, [{
    label: '.hc SOURCE',
    sub: 'Your Code'
  }, {
    label: 'LEX + PARSE',
    sub: 'Pratt Parser'
  }, {
    label: 'TYPE CHECK',
    sub: 'Hindley-Milner'
  }, {
    label: 'EMIT .kk',
    sub: 'Koka Source'
  }, {
    label: 'C / JS / WASM',
    sub: 'Native Binary',
    highlight: true
  }].map((step, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: step.label
  }, i > 0 && /*#__PURE__*/React.createElement(Icon, {
    name: "arrow-right",
    className: "text-[#e2e8f0] hidden md:block"
  }), /*#__PURE__*/React.createElement("div", {
    className: `w-full p-6 rounded-2xl border ${step.highlight ? 'border-2' : 'border-dashed border-[#e2e8f0] bg-[#f8fafc]'}`,
    style: step.highlight ? {
      backgroundColor: `${theme.indigo}08`,
      borderColor: theme.indigo
    } : {}
  }, /*#__PURE__*/React.createElement("span", {
    className: `block font-bold mb-1 tracking-[0.15em] text-xs uppercase ${step.highlight ? '' : 'text-[#64748b]'}`,
    style: step.highlight ? {
      color: theme.indigo
    } : {}
  }, step.label), /*#__PURE__*/React.createElement("span", {
    className: `text-sm font-bold ${step.highlight ? 'font-extrabold' : ''} text-[#1e293b]`
  }, step.sub))))), /*#__PURE__*/React.createElement("p", {
    className: "mt-16 text-xl text-[#64748b] max-w-2xl mx-auto leading-relaxed"
  }, "Each phase uses ", /*#__PURE__*/React.createElement("strong", null, "algebraic effects"), " for compiler state: diagnostics, type variables, and symbol scopes are all effect-tracked."))), /*#__PURE__*/React.createElement("section", {
    className: "py-24 bg-[#1e293b] relative overflow-hidden"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10"
  }, /*#__PURE__*/React.createElement("h2", {
    className: "text-4xl md:text-5xl font-bold text-white mb-10"
  }, "Get started"), /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col sm:flex-row justify-center gap-5"
  }, /*#__PURE__*/React.createElement("a", {
    href: "https://www.hica.dev/docs/quick-start",
    className: "px-10 py-4 rounded-xl font-bold text-lg text-white hover:opacity-90 transition-all flex items-center justify-center gap-2 shadow-lg",
    style: {
      backgroundColor: theme.indigo
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "book-open",
    size: 20
  }), " Quick Start"), /*#__PURE__*/React.createElement("a", {
    href: "https://www.hica.dev/playground/",
    className: "bg-transparent border-2 border-white/20 text-white px-10 py-4 rounded-xl font-bold text-lg hover:bg-white/10 transition-all flex items-center justify-center gap-2"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "graduation-cap",
    size: 20
  }), " Playground"), /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/cladam/hica",
    className: "bg-transparent border-2 border-white/20 text-white px-10 py-4 rounded-xl font-bold text-lg hover:bg-white/10 transition-all flex items-center justify-center gap-2"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "github",
    size: 20
  }), " Explore Source"))), /*#__PURE__*/React.createElement("div", {
    className: "absolute top-0 right-0 w-96 h-96 opacity-20 blur-[120px]",
    style: {
      backgroundColor: theme.indigo
    }
  }), /*#__PURE__*/React.createElement("div", {
    className: "absolute bottom-0 left-0 w-96 h-96 opacity-10 blur-[120px]",
    style: {
      backgroundColor: theme.cyan
    }
  })), /*#__PURE__*/React.createElement("footer", {
    className: "py-16 bg-white border-t border-[#e2e8f0]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col md:flex-row justify-between items-center gap-10 text-[#64748b] text-sm"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-5"
  }, /*#__PURE__*/React.createElement("img", {
    src: "assets/hica-logo2.png",
    alt: "hica Logo",
    className: "h-6 w-auto",
    onError: e => e.target.style.display = 'none'
  }), /*#__PURE__*/React.createElement("span", {
    className: "text-[#e2e8f0]"
  }, "|"), /*#__PURE__*/React.createElement("span", {
    className: "font-medium"
  }, "Open Source (Apache-2.0) by ", /*#__PURE__*/React.createElement("a", {
    href: "https://cladam.github.io",
    className: "hover:text-[#4f46e5] underline decoration-2 underline-offset-4 transition-colors"
  }, "Claes Adamsson"))), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-8 font-semibold"
  }, /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/cladam/hica/issues",
    className: "hover:text-[#1e293b] transition-colors"
  }, "Report Issue"), /*#__PURE__*/React.createElement("a", {
    href: "https://koka-lang.github.io/",
    className: "hover:text-[#1e293b] transition-colors"
  }, "Koka"), /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/cladam/hica"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "github",
    size: 20,
    className: "hover:text-[#1e293b] cursor-pointer transition-colors"
  })))))));
};
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(/*#__PURE__*/React.createElement(App, null));

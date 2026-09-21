// eslint-disable-next-line no-restricted-exports
export default {
  // Always: (x) => x (stable diffs, consistent style)
  arrowParens: 'always',
  bracketSameLine: false,
  bracketSpacing: true,
  embeddedLanguageFormatting: 'auto',
  endOfLine: 'lf',
  // Respect CSS-like whitespace handling in HTML
  htmlWhitespaceSensitivity: 'css',
  jsxSingleQuote: false,
  printWidth: 120,
  // Don't reflow prose (markdown/docs)
  proseWrap: 'preserve',
  quoteProps: 'as-needed',
  semi: true,
  singleAttributePerLine: false,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: false,
  overrides: [
    {
      // Wide lines keep inline markup intact instead of splitting tags
      files: 'misc/AI Product Engineer/AI Product Engineer Plan.html',
      options: { printWidth: 200 },
    },
  ],
};

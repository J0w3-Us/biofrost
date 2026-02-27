// Utilities to sanitize user-provided HTML/text before rendering in the UI.

/// Strips HTML tags while preserving paragraph/line-break structure.
///
/// Converts block elements (`<br>`, `<p>`, `<div>`, `<li>`) into real `\n`
/// so multi-paragraph rich-text from the canvas editor renders correctly
/// in Flutter's [Text] widget (which understands newlines but not HTML).
String stripHtmlKeepLines(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();

  // Block-level tags → newline
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

  // Strip all remaining tags
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode common HTML entities
  const entities = {
    '&nbsp;': ' ',
    '&lt;': '<',
    '&gt;': '>',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));

  // Collapse runs of spaces/tabs (but keep \n)
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');

  // Collapse more than two consecutive newlines
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return s.trim();
}

String sanitizeContent(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();

  // Remove HTML tags
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode a few common HTML entities
  const entities = {
    '&nbsp;': ' ',
    '&lt;': '<',
    '&gt;': '>',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));

  // Collapse multiple whitespace/newlines
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

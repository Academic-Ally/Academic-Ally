import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';

/// Recursively renders a Gen UI JSON tree into native Flutter widgets.
///
/// Schema (Phase 2):
///   { "type": "Column" | "Row", "children": [...] }
///   { "type": "Card", "title": "...", "body": "..." }
///   { "type": "List", "items": [{ "label": "...", "onTapRoute": "..." }] }
///   { "type": "Text", "value": "...", "size"?: int, "bold"?: bool }
///   { "type": "Button", "label": "...", "onTapRoute": "..." }
///
/// Unknown shapes render as a muted pill so rendering never crashes on an
/// LLM-hallucinated node — in Phase 4 this keeps bad output visible rather
/// than silently missing.
class GenUiRenderer extends StatelessWidget {
  final Map<String, dynamic> tree;

  const GenUiRenderer({super.key, required this.tree});

  @override
  Widget build(BuildContext context) => _render(context, tree);
}

Widget _render(BuildContext context, dynamic node) {
  if (node is! Map) return _unknownNode(node.toString());
  final type = node['type'];
  if (type is! String) return _unknownNode('missing type');

  switch (type) {
    case 'Column':
      return _column(context, node);
    case 'Row':
      return _row(context, node);
    case 'Card':
      return _card(context, node);
    case 'List':
      return _list(context, node);
    case 'Text':
      return _text(context, node);
    case 'Button':
      return _button(context, node);
    default:
      return _unknownNode(type);
  }
}

Widget _column(BuildContext context, Map node) {
  final children = (node['children'] as List<dynamic>? ?? const [])
      .map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _render(context, c),
          ))
      .toList();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

Widget _row(BuildContext context, Map node) {
  final children = (node['children'] as List<dynamic>? ?? const [])
      .map((c) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _render(context, c),
          ))
      .toList();
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: children),
  );
}

Widget _card(BuildContext context, Map node) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final title = node['title']?.toString() ?? '';
  final body = node['body']?.toString() ?? '';
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        if (title.isNotEmpty && body.isNotEmpty) const SizedBox(height: 6),
        if (body.isNotEmpty)
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF161719),
              height: 1.4,
            ),
          ),
      ],
    ),
  );
}

Widget _list(BuildContext context, Map node) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final items = (node['items'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
  if (items.isEmpty) return const SizedBox.shrink();

  return Container(
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          InkWell(
            onTap: _tapHandler(context, items[i]['onTapRoute']),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i]['label']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                      ),
                    ),
                  ),
                  if (items[i]['onTapRoute'] != null)
                    const Icon(Icons.keyboard_arrow_right,
                        color: Colors.grey),
                ],
              ),
            ),
          ),
          if (i != items.length - 1)
            Divider(
              height: 0,
              color: Colors.grey[300],
              indent: 16,
              endIndent: 16,
            ),
        ],
      ],
    ),
  );
}

Widget _text(BuildContext context, Map node) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final value = node['value']?.toString() ?? '';
  final size = (node['size'] as num?)?.toDouble() ?? 13;
  final bold = node['bold'] == true;
  return Text(
    value,
    style: GoogleFonts.poppins(
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: isDark ? Colors.white : const Color(0xFF161719),
    ),
  );
}

Widget _button(BuildContext context, Map node) {
  final label = node['label']?.toString() ?? 'Action';
  final onTap = _tapHandler(context, node['onTapRoute']);
  return SizedBox(
    width: double.infinity,
    height: 44,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
    ),
  );
}

VoidCallback? _tapHandler(BuildContext context, dynamic routeRaw) {
  if (routeRaw is! String || !routeRaw.startsWith('/')) return null;
  return () => context.push(routeRaw);
}

Widget _unknownNode(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'Unknown widget: $label',
      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
    ),
  );
}

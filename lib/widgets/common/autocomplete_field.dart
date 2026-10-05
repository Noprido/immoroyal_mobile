// widgets/common/autocomplete_field.dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/text_normalize.dart';

class AutocompleteField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final List<String> suggestions;
  final IconData? icon;

  const AutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    required this.suggestions,
    this.hint,
    this.icon,
  });

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _filter(String query) {
    final q = normalize(query);
    if (q.isEmpty) return const [];
    final matches = widget.suggestions.where((s) => normalize(s).contains(q)).toList();
    matches.sort((a, b) {
      final aStarts = normalize(a).startsWith(q) ? 0 : 1;
      final bStarts = normalize(b).startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.length - b.length;
    });
    return matches.take(8).toList();
  }

  Widget _highlighted(String text, String query) {
    final normText = normalize(text);
    final normQuery = normalize(query);
    final idx = normText.indexOf(normQuery);
    if (idx == -1 || query.isEmpty) return Text(text, style: AppText.bodySmall);

    return RichText(
      text: TextSpan(
        style: AppText.bodySmall.copyWith(color: kBlack),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700, color: kGoldDark),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.label),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (value) => _filter(value.text),
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.icon != null ? Icon(widget.icon, size: 18) : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 220,
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final option = options.elementAt(i);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: _highlighted(option, widget.controller.text),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
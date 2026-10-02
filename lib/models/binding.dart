/// Widget types that can be bound to variables (section 8 of the README).
enum WidgetKind { listView, text, image, form, button }

extension WidgetKindLabel on WidgetKind {
  String get label => switch (this) {
    WidgetKind.listView => 'ListView',
    WidgetKind.text => 'Text',
    WidgetKind.image => 'Image',
    WidgetKind.form => 'Form',
    WidgetKind.button => 'Button',
  };
}

/// A single field within a bound widget, e.g. `product.name`.
class BindingField {
  const BindingField({required this.label, required this.expression});

  final String label;
  final String expression;
}

/// Connects a widget to a variable, e.g. ListView -> products.
class WidgetBinding {
  const WidgetBinding({
    required this.id,
    required this.widgetName,
    required this.kind,
    this.sourceVariableId,
    this.itemLabel = 'item',
    this.fields = const <BindingField>[],
  });

  final String id;
  final String widgetName;
  final WidgetKind kind;
  final String? sourceVariableId;
  final String itemLabel;
  final List<BindingField> fields;
}

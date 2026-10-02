import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The main sections of the AppMaker visual builder.
enum BuilderSection { variables, apis, actions, mapping, bindings }

extension BuilderSectionMeta on BuilderSection {
  String get label => switch (this) {
    BuilderSection.variables => 'Variables',
    BuilderSection.apis => 'APIs',
    BuilderSection.actions => 'Actions',
    BuilderSection.mapping => 'Mapping',
    BuilderSection.bindings => 'Bindings',
  };

  String get description => switch (this) {
    BuilderSection.variables => 'Reusable application state',
    BuilderSection.apis => 'Reusable API definitions',
    BuilderSection.actions => 'Connect APIs, state and navigation',
    BuilderSection.mapping => 'Map responses into variables',
    BuilderSection.bindings => 'Connect data to widgets',
  };
}

class BuilderSectionNotifier extends Notifier<BuilderSection> {
  @override
  BuilderSection build() => BuilderSection.actions;

  void select(BuilderSection section) => state = section;
}

final builderSectionProvider =
    NotifierProvider<BuilderSectionNotifier, BuilderSection>(
      BuilderSectionNotifier.new,
    );

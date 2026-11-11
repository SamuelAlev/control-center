# Ratchet allowlists

Each `.txt` file here is a shrinking allowlist read by a ratchet test. The test
fails when a file breaks the rule without being listed (a new violation: fix it
instead of listing it) or when a listed path no longer breaks the rule or was
deleted (a stale entry: prune it). Remove an entry in the same change that fixes
the file. An empty list is a hard ban.

Format: one repo-relative path per line. Blank lines and `#` comments are ignored.

| File | Rule | Test |
| --- | --- | --- |
| `material_importers.txt` | `lib/` files still importing `package:material_ui/material_ui.dart` (`package:flutter/material.dart` is banned outright) | `architecture_constraints_test.dart` |
| `cupertino_importers.txt` | `lib/` files still importing `package:cupertino_ui/cupertino_ui.dart` (`package:flutter/cupertino.dart` is banned outright) | `architecture_constraints_test.dart` |
| `material_components.txt` | `lib/` files still using a banned Material component widget | `architecture_constraints_test.dart` |
| `core_features_importers.txt` | `lib/core` files importing `lib/features` | `architecture_constraints_test.dart` |
| `shared_features_importers.txt` | `lib/shared` files importing `lib/features` | `architecture_constraints_test.dart` |
| `settings_feature_importers.txt` | `lib/features/settings` files importing another feature's presentation | `architecture_constraints_test.dart` |
| `presentation_data_importers.txt` | presentation files importing a feature `data/` layer | `architecture_constraints_test.dart` |
| `features_cc_data_importers.txt` | `lib/features` files importing `package:cc_data` directly | `architecture_constraints_test.dart` |
| `dart_isolate_importers.txt` | web-reachable files importing `dart:isolate` | `architecture_constraints_test.dart` |
| `domain_entities_without_equality.txt` | `cc_domain` entity files without `==`/`hashCode` | `architecture_constraints_test.dart` |
| `domain_value_objects_without_equality.txt` | `cc_domain` value-object files without `==`/`hashCode` | `architecture_constraints_test.dart` |
| `domain_repositories_without_implementations.txt` | `cc_domain` repository interfaces with no implementation | `architecture_constraints_test.dart` |
| `rtl_physical_geometry.txt` | files using physical-edge geometry that should mirror under RTL | `rtl_directionality_ratchet_test.dart` |

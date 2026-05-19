# UI vendor migration allowlists

These files drive the ratcheting rules in
[`../architecture_constraints_test.dart`](../architecture_constraints_test.dart)
that track the migration of Material/Cupertino visual widgets onto the in-repo
`cc_ui` design-system package (`packages/cc_ui`).

- `material_importers.txt` — `lib/` files still importing `package:flutter/material.dart`.
- `cupertino_importers.txt` — `lib/` files still importing `package:flutter/cupertino.dart`.

Format: one repo-relative path per line. Blank lines and `#` comments are ignored.

## Rules

For each list the test fails if **either**:

1. a `lib/` file imports the vendor but is **not** in the list (a new, disallowed
   import — migrate it to `cc_ui` instead), or
2. a listed path **no longer** imports the vendor or was deleted (a stale entry —
   prune it).

So every migration must remove the migrated file from the relevant list in the
same change. When a list becomes empty the ban is absolute; at that point the
file and its rule can be deleted (Wave 4).

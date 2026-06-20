---
description: Update Godot theme variants to point to specific texture assets
---

This workflow guides you through updating Godot `.tres` theme files to use specific texture assets instead of a shared base texture.

1. **Identify Files**
   Identify the target theme file (e.g., `Theme-Variant.tres`) and the corresponding texture file (e.g., `texture_variant.png`).

2. **Get Texture UID**
   Get the unique ID (UID) of the new texture from its import file.
   // turbo
   ```bash
   grep "uid=" PATH_TO_TEXTURE.png.import
   ```

3. **Find Resource Line**
   Find the existing `ext_resource` line in the theme file that points to the old texture.
   // turbo
   ```bash
   grep -n "ext_resource type=\"Texture2D\"" PATH_TO_THEME.tres
   ```

4. **Update Theme File**
   Use `replace_file_content` to update the theme file.
   - Target the line found in step 3.
   - Replace the `path` with the new texture path (start with `res://`).
   - Replace the `uid` with the UID found in step 2.
   - **Crucial**: Keep the `id="..."` field matching the original file to preserve internal references.

5. **Verify**
   Check that the file now references the correct texture.
   // turbo
   ```bash
   grep "ext_resource type=\"Texture2D\"" PATH_TO_THEME.tres
   ```

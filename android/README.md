# Android signing keys — do not commit

Place your keystores here. `*.keystore` and `keystore.properties` are
covered by the repo `.gitignore`, but **double-check** before pushing.

## Generating a release keystore (one-time)

```bash
keytool -genkey -v \
  -keystore android/release.keystore \
  -alias voxeldungeon \
  -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted for:
- **keystore password** — needed by `export_presets.cfg`
- **key password** — same as keystore password is fine for personal use
- name / org info — fill in anything; this is not a published app

## Keeping the password out of git

`export_presets.cfg` is **committed**, so do not put the real password in
the `keystore/release_password` field there. Two safe alternatives:

1. **Local override file** (recommended)
   - Set the password in `export_presets.cfg` only on your machine.
   - Use a per-machine git worktree exclude so changes to it are ignored:
     ```bash
     git update-index --skip-worktree export_presets.cfg
     ```

2. **Environment variable**
   - Leave `keystore/release_password=""` in the committed file.
   - Export the password before running Godot:
     ```bash
     export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="..."
     godot --editor
     ```

## Files in this directory

| File | Purpose | Tracked? |
|---|---|---|
| `release.keystore` | Release signing key | **No** (gitignored) |
| `debug.keystore` | Local debug key (Godot can auto-generate) | **No** (gitignored) |
| `keystore.properties` | Optional helper file with paths | **No** (gitignored) |
| `README.md` | This file | Yes |

## Recovery

**If you lose the release keystore, you cannot publish updates to the same
app on Google Play.** Back up `release.keystore` to a password manager or
encrypted volume after generating it.

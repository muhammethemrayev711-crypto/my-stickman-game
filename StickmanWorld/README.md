# Stickman World — Godot 4 prototype

This is a first playable foundation, not the finished online game described in the design conversation.

## Included now
- Lightweight 3D neighborhood scene built from simple meshes.
- A stylized, moderately proportioned stickman player.
- Third-person camera with touch drag control.
- Left-side virtual movement area.
- Enter/exit interaction zones for a mosque, home, cafe, shop and lesson-center placeholder.
- Simple indoor placeholder scenes.
- Prayer preference setup saved locally on the device.
- Android export workflow starter.

## Not implemented yet
- Real prayer-time calculation, city/location selection, online time synchronization and reliable Android background notifications.
- Actual Hayalhanem videos or their playback. Add only content you have permission to use.
- Real multiplayer server, accounts, friends, chat, visits between players and persistent shared city.
- Full character customization, female character model, detailed animations, vehicles, construction/economy and finished building interiors.
- Production-ready assets, sound, accessibility, privacy/security review and device testing.

These are substantial systems and should not be represented as already working. The project is intentionally a lightweight foundation that can be expanded.

## Open locally
Open the folder in Godot 4.3 or newer and run `Scenes/Main.tscn`.

## Android build
The GitHub Actions workflow in `.github/workflows/android.yml` attempts an Android export using the `Android` preset. Check the workflow log if the export image/toolchain version needs adjustment. A public repository's standard GitHub-hosted Actions usage is free under GitHub's current policy, but account limits and artifact retention can change.

## Notes
- Renderer: Compatibility (mobile-friendly).
- No external fonts, CDNs or runtime web dependencies.
- Local player settings are stored in `user://player.cfg`.

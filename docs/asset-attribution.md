# Assets and attribution

Runtime assets include contextual artwork from the supplied design exports, verified SVG families and Noto Sans Arabic / Roboto. Full-screen exports are not runtime dependencies. Crop coordinates, export basenames and vector origins remain in [asset-provenance.json](asset-provenance.json).

| Resource | Attribution / license |
| --- | --- |
| Noto Sans Arabic | Noto font contributors; SIL Open Font License, retained in `assets/licenses/NotoSansArabic-OFL.txt`. |
| Roboto | Roboto Project Authors; [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/roboto), SIL Open Font License in `assets/licenses/Roboto-OFL.txt`. |
| Iconamoon | Dariush Habibpour; [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Credit/source retained in `icon-credits.txt`. |
| Lucide / Iconoir | Lucide Contributors, ISC; Luca Burgio/Iconoir, MIT. Full notices bundled. |
| Material Symbols / WeUI | Google, Apache 2.0; WeUI, MIT. Full notices bundled. |
| Supplied PNGs | Project design artwork cropped for screen contexts. No independent distribution license is established by this document. |

Flutter registers bundled notices with `LicenseRegistry`. Framework/package licenses retain upstream terms; the Cupertino font supplies framework iOS controls rather than replacing design icons.

Audit dynamic names as well as literal references: navigation, social images, categories, course illustrations and SourceIcon enum values. Native Android splash/launcher resources under `android/app/src/main/res/` are separate from the Flutter manifest.

The unused Cairo pair and undeclared duplicate Noto license copy were removed from assets. The active Noto font, runtime license, required icons/artwork and native branding remain. `test/bundled_assets_test.dart` verifies dynamic names and resource loading.

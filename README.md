# cember

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Web yayını (cember.org)

Her `firebase deploy --only hosting` öncesi: `flutter build web --release && (cd test-rules && npm install && npm run yayin-oncesi)` — sıfırdan farklı çıkarsa deploy etme.
Betik yalnız kontrol eder: FlutterFire satır içi betik hash'leri `firebase.json` CSP'sinde mi, canlıdaki alt siteler (`/milestones/`, `/cakabey/`) `build/web`'de var mı (deploy tam yansımadır, olmayanı siler).
`/cakabey/` depodaki `web/cakabey/`'den gelir; `/milestones/` depoda YOKTUR: `~/milestones-coffee` deposunda `python3 scripts/build.py` ile üretilen `dist/milestones` klasörü deploy'dan önce `build/web/milestones` olarak kopyalanmalıdır (bkz. o depodaki `scripts/yayinla.sh`).

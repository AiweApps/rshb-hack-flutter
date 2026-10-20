# Внешние пакеты локального распознавания

В Git включён код приложений, native bridges и Python-правил. Веса, индексы,
подготовленная сериализованная policy и платформенные Python/OpenCV-библиотеки
поставляются отдельно. Нельзя заменять их случайными файлами похожих версий:
приложение проверяет точные SHA и сохраняет прежние ограничения запросов.

## Android

Разместите относительно `kmp/`:

```text
external/android/bundle-assets-v2/bundle.json
external/android/bundle-assets-v2/payload/...
external/android/jniLibs/arm64-v8a/...
```

Манифест bundle: `2ffae2ec2a5b04f7fa9a1b930fe74d2818d2513438ddb922479500ff1bd989e5`.
Пакет моделей, устанавливаемый отдельно в private app storage:
`3accf0e45542ce89b24c8f31266818f8931632c5bf5511a8fa08d13cd5d3a2ff`.
Точные проверки и пути находятся в `AndroidLocalPins.kt` и
`AndroidLocalScanEngine.kt`. При необходимости задайте `WINE_BUILD_PYTHON` — путь
к Python 3.12 на машине сборки. По умолчанию используется `python3.12` из PATH.

Состав: ONNX FP32, OCR V6/V5, CPython 3.12 и native geometry. Требуется arm64-v8a.
Автоматическая загрузка Android-пакета моделей в этом снимке не реализована.

## iOS

```text
external/ios/apple-python-3.12-b11/unpacked/Python.xcframework/...
external/ios/app-runtime-simulator-v1/receipt.json
external/ios/app-runtime-simulator-v1/Runtime.app/...
external/ios/app-runtime-device-v1/receipt.json
external/ios/app-runtime-device-v1/Runtime.app/...
external/ios/policy/policy-manifest.json
external/ios/policy/...
external/ios/candidate-assets-v3/assets.json
external/ios/candidate-assets-v3/...
```

Полный контракт: `config/ondevice-ios-candidate-v1.json`.
Policy manifest SHA: `35dedbd1d4f880503c024a3eeb25cbcb2ad627c2d88334a372d66b4fb7349808`.
Native assets manifest SHA: `5db12023083b1343d4d0b6d96e2e104ab2d97aa0416f16ec32aec324928fb9c3`.
`scripts/stage_ondevice_policy_runtime.py` проверяет каждый файл пакетов до копирования
в производную `.app`; `scripts/stage_ondevice_ios_assets.py` проверяет модели.
Не изменяйте манифесты, чтобы обойти несовпадение.

`iosApp` — Server с ручным выбором Local. Модели скачиваются через Settings с
действующего API и проверяются по SHA. `iosApp-Local` встраивает модели при сборке
и потому дополнительно требует `candidate-assets-v3` на машине сборки.
Python, policy и native runtime нужны обоим типам.

Внешние пакеты не включают пользовательскую историю, фотографии сканов или токены.
Самостоятельная подготовка заменяющего пакета требует отдельного переноса и проверки;
команды Gradle/Xcode не создают его из весов автоматически.

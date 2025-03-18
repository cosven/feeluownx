# FeelUOwnX

# Contribution Guide

```sh
dart run serious_python:main package -p Android app/src \
     -r cffi -r json-rpc  -r ../../feeluown \
     -r fuo-netease -r fuo-qqmusic -r fuo-ytmusic \
     --verbose

# Better not run daemon when debugging UI, since it will cause hot reload to fail
# https://github.com/flet-dev/serious-python/issues/89
flutter run --dart-define=ENABLE_FUO_DAEMON=false -d DEVICE_ID --verbose
```

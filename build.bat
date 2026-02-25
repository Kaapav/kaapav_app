@echo off
echo === KAAPAV CLEAN BUILD ===

echo Cleaning Flutter...
call flutter clean

echo Removing build cache...
rmdir /s /q build 2>nul
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul

echo Getting packages...
call flutter pub get

echo Building release APK...
call flutter build apk --release --no-tree-shake-icons

echo === BUILD COMPLETE ===
echo APK: build\app\outputs\flutter-apk\app-release.apk
pause
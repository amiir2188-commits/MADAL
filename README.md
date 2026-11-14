# MADAL
Somali Stories and Podcast Platform

name: Build MADAL Android APK

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21

      - name: Prepare app
        run: |
          mkdir -p www
          cp index.html www/
          cp manifest.webmanifest www/ 2>/dev/null || true
          cp sw.js www/ 2>/dev/null || true
          cp -r icons www/ 2>/dev/null || true
          npm init -y
          npm install @capacitor/core @capacitor/android
          npm install -D @capacitor/cli
          npx cap init MADAL com.madal.app --web-dir www
          npx cap add android
          npx cap sync android

      - name: Build APK
        run: |
          cd android
          chmod +x gradlew
          ./gradlew assembleDebug

      - uses: actions/upload-artifact@v4
        with:
          name: MADAL-Android-APK
          path: android/app/build/outputs/apk/debug/app-debug.apk

#!/bin/bash

# تعريف الألوان
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== بدء عملية النشر المحسنة (IDX Optimized) ===${NC}"

# 1. تنظيف البيئة (ضروري جداً لتوفير المساحة)
echo -e "${GREEN}1. Cleaning workspace to free space...${NC}"
flutter clean
rm -rf deploy
mkdir -p deploy

# 2. جلب المكتبات
echo -e "${GREEN}2. Fetching dependencies...${NC}"
flutter pub get

# 3. بناء نسخة الإنتاج
echo -e "${GREEN}3. Building Production APK...${NC}"
# استخدام flavor prod وملف main_prod.dart
flutter build apk --flavor prod -t lib/main_prod.dart --release

# التحقق من نجاح البناء
if [ ! -f "build/app/outputs/flutter-apk/app-prod-release.apk" ]; then
    echo "Error: Build failed! APK not found."
    exit 1
fi

# 4. تجهيز ملف النشر
echo -e "${GREEN}4. Preparing deployment...${NC}"
cp build/app/outputs/flutter-apk/app-prod-release.apk deploy/Guardian_App_Latest.apk

# 5. الرفع إلى GitHub
echo -e "${GREEN}5. Pushing to GitHub...${NC}"
# إعدادات Git المؤقتة لهذا السكريبت
git config --global user.email "idx-builder@example.com"
git config --global user.name "IDX Builder"

git add deploy/Guardian_App_Latest.apk
git commit -m "Deploy: New Release Build [$(date)]"
git push origin main

echo -e "${GREEN}=== تمت عملية النشر بنجاح! ===${NC}"
echo "رابط التحميل المباشر: https://github.com/omna25data-afk/qlm_guardian_app/blob/main/deploy/Guardian_App_Latest.apk"
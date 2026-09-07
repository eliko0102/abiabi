#!/bin/bash

# 🚀 AI Business Agent - APK Build Script
# Kullanım: ./build-apk.sh

set -e

echo "================================"
echo "📱 APK İnşa Başladı"
echo "================================"
echo ""

# Kurulum Kontrol
echo "1️⃣ Flutter ve Android Kontrol Ediliyor..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter bulunamadı!"
    echo "Flutter indir: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter: $(flutter --version | head -1)"

if ! command -v java &> /dev/null; then
    echo "❌ Java bulunamadı! JDK 11+ gerekli"
    exit 1
fi

echo "✅ Java: $(java -version 2>&1 | head -1)"

# Flutter Doctor
echo ""
echo "2️⃣ Sistem Kontrol Ediliyor..."
flutter doctor

# Bağımlılıklar
echo ""
echo "3️⃣ Bağımlılıklar Yükleniyor..."
flutter pub get

# APK İnşa Et
echo ""
echo "4️⃣ Debug APK İnşa Ediliyor..."
flutter build apk --debug

echo ""
echo "✅ Debug APK HAZIR:"
echo "   📍 build/app/outputs/flutter-apk/app-debug.apk"
echo ""

# Release APK
echo "5️⃣ Release APK İnşa Ediliyor..."
flutter build apk --release

echo ""
echo "✅ Release APK HAZIR:"
echo "   📍 build/app/outputs/flutter-apk/app-release.apk"
echo ""

echo "================================"
echo "🎉 APK İnşa Tamamlandı!"
echo "================================"
echo ""
echo "📱 Telefona Yüklemek İçin:"
echo "   flutter install"
echo ""
echo "📦 APK Özellikleri:"
echo "   • Package ID: com.aiagent.com"
echo "   • Versiyon: 1.0.0 (Build: 1)"
echo "   • Backend Bağlantı: http://127.0.0.1:5000"
echo ""
echo "🧪 Test Edebileceğiniz Özellikler:"
echo "   ✅ Kayıt Ekranı (Sign Up)"
echo "   ✅ Giriş Ekranı (Login)"
echo "   ✅ MongoDB Veritabanı"
echo "   ✅ JWT Token Kimlik Doğrulama"
echo "   ✅ Gemini AI Chat"
echo "   ✅ İşletme Analizi"
echo ""
echo "💡 İpuçları:"
echo "   • Backend'i çalıştırmayı unutmayın: npm run dev (backend klasöründe)"
echo "   • İnternet bağlantısının aktif olduğundan emin olun"
echo "   • Telefon ile bilgisayar aynı ağda olmalı"
echo ""

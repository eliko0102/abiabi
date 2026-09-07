import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'services/ai_service.dart';
import 'services/report_service.dart';
import 'services/mongo_auth_service.dart';
import 'services/social_auth_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/business_api_service.dart';
import 'services/audit_history_service.dart';
import 'config/api_config.dart';
import 'screens/product_flow.dart';

void main() {
  runApp(const AiBusinessAgentApp());
}

// ============================================================
// DESIGN TOKENS
// Bir yerdə saxlanılan rənglər / boşluqlar / radiuslar sayəsində
// bütün UI eyni "dil"də danışır — qarışıqlıq buradan yaranırdı.
// ============================================================
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

class AppColors {
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF14B8A6); // Teal accent
  static const Color surfaceLight = Color(0xFFF7F8FC);
  static const Color surfaceDark = Color(0xFF0B1120);
}

class AppLocalizations extends InheritedWidget {
  final Locale locale;

  const AppLocalizations({
    super.key,
    required this.locale,
    required super.child,
  });

  static const Map<String, Map<String, String>> _localizedValues = {
    'az': {
      'appTitle': 'EAI Asistent',
      'login': 'Daxil ol',
      'register': 'Qeydiyyat',
      'emailOrUsername': 'E-poçt və ya istifadəçi adı',
      'emailAddress': 'E-poçt ünvanı',
      'fullName': 'Ad və soyad',
      'dateOfBirth': 'Doğum tarixi',
      'selectDate': 'Tarix seçin',
      'google': 'Google',
      'apple': 'Apple',
      'or': 'və ya',
      'aiBackendError': 'Hazırda AI serverinə qoşulmaq mümkün olmadı.',
      'liveReportTitle': 'Canlı 2GIS hesabatı:',
      'liveLocationIndex': 'Məkan indeksi',
      'liveTrafficIndex': 'Piyada trafik indeksi',
      'liveCompetitors': '500 m-də rəqiblər',
      'liveNearest': 'Ən yaxın rəqib',
      'liveMapHint': 'Rəqiblərin nöqtələrini Xəritə panelində görə bilərsiniz.',
      'invalidEmail': 'Düzgün e-poçt ünvanı daxil edin.',
      'weakPassword': 'Şifrə ən azı 6 simvol olmalıdır.',
      'password': 'Şifrə',
      'staySignedIn': 'Daxil ol saxla',
      'biometricLogin': 'Barmaq izi ilə daxil ol',
      'welcomeBack': 'Xoş gəlmisiniz',
      'description':
          'Biznes ideyaları, bazar analizi və yerli təkliflər üçün süni intellekt əsaslı yardım.',
      'profileHeader': 'Profil',
      'logout': 'Hesabdan çıxış',
      'logoutConfirm': 'Hesabdan çıxmaq istəyirsiniz?',
      'cancel': 'Ləğv et',
      'deleteAudit': 'Auditi sil',
      'deleteAuditConfirm': 'Bu yadda saxlanılmış auditi silmək istəyirsiniz?',
      'demoAccountHeader': 'Demo Hesab Məlumatları',
      'demoPagesHeader': 'Demo Səhifələr',
      'dashboardTitle': 'Sizə uyğun günə baxış',
      'dashboardSubtitle': 'Hesabınız və növbəti addımlar üçün aydın görünüş.',
      'todayAtAGlance': 'Bu günə baxış',
      'quickActions': 'Sürətli hərəkətlər',
      'businessPulse': 'Biznes ritmi',
      'businessPulseValue': '3 hazır fikir',
      'businessPulseSubtitle': 'Yerli tendensiyalar ümidvericidir',
      'clientFocus': 'Müştəri diqqəti',
      'clientFocusValue': '2 prioritet tapşırıq',
      'clientFocusSubtitle': 'Bu gün izləyin',
      'aiHelp': 'AI yardım',
      'aiHelpValue': 'İstənilən şeyi soruşun',
      'aiHelpSubtitle': 'Bazar, qiymət və satış',
      'openAssistant': 'Assistenti aç',
      'reviewNotifications': 'Bildirişləri yoxlayın',
      'mapTitle': 'Xəritə',
      'currentLocation': 'Cari məkan',
      'mapSubtitle': 'Qazaxıstan bölgələri və iş imkanları',
      'mapCities': 'Astana, Almatı, Şımkənd, Aktau',
      'mapDetail': 'İş ehtiyatları və regional inkişaf üçün sürətli baxış',
      'assistantTitle': 'Sizin AI köməkçiniz',
      'assistantSubtitle':
          'Biznes ideyalar, bazar yoxlamaları və növbəti addımlar üçün yardım edin.',
      'assistantHint': 'Sualınızı yazın...',
      'assistantStartNew': 'Sıfırdan bölgə seç',
      'assistantOwnAddress': 'Öz ünvanım var',
      'assistantBusinessQuestion': 'Əla! Hansı sahə sizi maraqlandırır?',
      'assistantFood': 'İctimai iaşə',
      'assistantRetail': 'Məhsullar',
      'assistantBeauty': 'Gözəllik',
      'assistantOther': '+ Digər',
      'menu': 'Menyu',
      'assistantSend': 'Göndər',
      'profileSubtitle': 'Bildirişləri, dili və hesab ayarlarını idarə edin.',
      'entrepreneur': 'Sahibkar',
      'planPro': 'Tarif: Pro',
      'savedAudits': 'YADDA SAXLANILMIŞ AUDİTLƏRİM',
      'settingsTitle': 'AYARLAR',
      'savedAudit1': 'Aktau, 14-cü mikrorayon',
      'savedAudit2': 'Aktau, Samal',
      'savedAudit3': 'Aktau, 3-cü mikrorayon',
      'auditDate1': '18 avq 2026 tarixində analiz',
      'auditDate2': '12 avq 2026 tarixində analiz',
      'auditDate3': '05 avq 2026 tarixində analiz',
      'newCompetitors': 'Yeni rəqiblər',
      'notifyCompetitors': 'Yaxınlıqdakı yeniliklər barədə bildir',
      'auditStatus': 'Hazır',
      'noAudits': 'Hələ heç bir audit yoxdur',
      'profileName': 'Ad',
      'profilePhone': 'Telefon',
      'profileLanguage': 'Dil',
      'profileTheme': 'Tema',
      'profileOtpDelivery': 'OTP çatdırılması',
      'notificationsTitle': 'Bildirişlər',
      'theme': 'Tema',
      'language': 'Dil',
      'toggleTheme': 'Temanı dəyiş',
      'selectLanguage': 'Dili seçin',
      'receiveOtpVia': 'OTP-ni necə qəbul edin',
      'enterUsernamePassword': 'İstifadəçi adı və şifrəni daxil edin',
      'haveAccount': 'Hesabınız var?',
      'needAccount': 'Hesab lazımdır?',
      'continueAsGuest': 'Qonaq kimi davam et',
      'otpMethod': 'Giriş üsulu',
      'phoneOtp': 'Mobil nömrə (SMS)',
      'emailOtp': 'E-poçt (OTP)',
      'whatsappOtp': 'WhatsApp (OTP)',
      'languageSettings': 'Dil seçimləri',
      'themeSettings': 'Tema seçimləri',
      'themeDescription': 'Açıq, qaranlıq və ya avtomatik rejimi seçin',
      'languageDescription': 'Azerbaycan, Rus və Qazax dillerində interfeys',
      'dashboardHeroTitle': 'Günün əsas hərəkətləri',
      'dashboardHeroSubtitle': 'Günün əsas məqsədləri üzrə operativ baxış',
      'dashboardHeroChip': 'Yeni ideya hazır',
      'dashboardActionTitle': 'Növbəti addım',
      'dashboardActionSubtitle': 'Bir kliklə asistentə keçin',
      'close': 'Bağla',
      'openInMaps': 'İstiqamət al',
      'businessHotspot': 'İş imkanı bölgəsi',
      'noNotifications': 'Yeni bildiriş yoxdur',
      'navDashboard': 'Panel',
      'navMap': 'Xəritə',
      'navAssistant': 'Assistant',
      'navProfile': 'Profil',
      'free': 'PULSUZ',
      'nextIdeaTitle': 'Tochka.ai ilə növbəti məkanınızı risk etmədən seçin',
      'nextIdeaSubtitle':
          'İdeyanızı, büdcənizi və regionu yoxlayın. Sonra ən güclü 3 ünvanı müqayisə edin.',
      'analysisStart': 'Analizə necə başlayaq?',
      'idea': 'İdeya',
      'place': 'Məkan',
      'decision': 'Qərar',
      'deepAnalytics': 'İlkin dərin analitika',
      'viabilityForecast': 'Yaşama qabiliyyəti — ilk fəaliyyət ilində proqnoz',
      'riskSimilarBusinesses': '500 m radiusda 6 analoji biznes var',
      'riskVisibility': 'Giriş görünürlüğünü sahədə yoxlayın',
      'unlockRisks': '2 kritik riski və tam hesablamanı aç',
      'calculatorTitle': 'Xərcini çıxarma kalkulyatoru',
      'monthlyRent': 'Aylıq icarə (₸)',
      'averageTicket': 'Orta çek (₸)',
      'calculate': 'Hesabla',
      'customersNeeded':
          'Mənfəətə çıxmaq üçün gündə təxminən {count} alıcı lazımdır.',
      'plansTitle': 'Tochka.ai tarifləri',
      'planFreeSubtitle': 'Üçfaktorlu çat + xəritə + məkan balı',
      'planOneSubtitle': 'Tam analiz + PDF + danışıqlar mətni',
      'planThreeSubtitle': 'Yanaşı müqayisə ilə tam analiz',
      'continue': 'Davam et',
      'searchAddressHint': 'Şəhər və ya ünvan axtar...',
      'search': 'Axtar',
      'addressNotFound': 'Ünvan tapılmadı. Daha dəqiq yazın.',
      'locationIndex': 'Məkan indeksi',
      'footTraffic': 'Piyada trafiki',
      'high': 'Yüksək',
      'competitors': 'Rəqiblər (500 m)',
      'competitorList': 'Tapılan rəqiblər',
      'distance': 'Məsafə',
      'parking': 'Parking',
      'stops': 'Dayanacaq',
      'reviews': 'Rəy',
      'traffic': 'Trafik',
      'trafficUnavailable': 'Məlumat yoxdur',
      'hoursAvailable': 'İş qrafiki var',
      'nearestDistance': 'Ən yaxın rəqib',
      'analysisUnavailable': '2GIS analizi əlçatan deyil',
      'analyzing': 'Analiz edilir...',
      'locationPassport': 'PDF Məkan Pasportu',
      'whatsappNegotiation': 'WhatsApp danışıqlar mətni',
      'stopListening': 'Dinləməni dayandır',
      'voiceInput': 'Səslə yaz',
      'smsEmailWhatsapp': 'SMS, E-poçt, WhatsApp',
      'languageEnglish': 'English',
      'personaBaba': 'Müdrik Baba',
      'personaBabaHint': 'Riskləri azaldır',
      'personaMarketer': 'Kreativ Marketoloq',
      'personaMarketerHint': 'Fərqlənməyə kömək edir',
      'personaAnalyst': 'Sərt Analitik',
      'personaAnalystHint': 'Quru rəqəmlər və ROI',
      'assistantWelcome':
          'Salam! Biznesiniz üçün ideal məkanı tapmağa kömək edəcəyəm. Artıq nəzərdə tutduğunuz obyekt var, yoxsa ən yaxşı ərazini sıfırdan seçməyimi istəyirsiniz?',
    },
    'en': {
      'appTitle': 'EAI Assistant',
      'login': 'Log in',
      'register': 'Sign up',
      'emailAddress': 'Email address',
      'fullName': 'Full name',
      'dateOfBirth': 'Date of birth',
      'selectDate': 'Select date',
      'google': 'Google',
      'apple': 'Apple',
      'or': 'or',
      'aiBackendError': 'The AI server could not be reached right now.',
      'liveReportTitle': 'Live 2GIS report:',
      'liveLocationIndex': 'Location index',
      'liveTrafficIndex': 'Pedestrian traffic index',
      'liveCompetitors': 'Competitors within 500 m',
      'liveNearest': 'Nearest competitor',
      'liveMapHint': 'You can see competitor points in the Map panel.',
      'password': 'Password',
      'invalidEmail': 'Enter a valid email address.',
      'weakPassword': 'Password must be at least 6 characters.',
      'staySignedIn': 'Keep me signed in',
      'biometricLogin': 'Sign in with fingerprint',
      'description':
          'AI-powered help for business ideas, market analysis and local offers.',
      'haveAccount': 'Already have an account?',
      'needAccount': 'Need an account?',
      'continueAsGuest': 'Continue as guest',
      'otpMethod': 'Sign-in method',
      'phoneOtp': 'Mobile number (SMS)',
      'emailOtp': 'Email (OTP)',
      'whatsappOtp': 'WhatsApp (OTP)',
      'selectLanguage': 'Select language',
      'language': 'Language',
      'theme': 'Theme',
      'dashboardTitle': 'Your daily overview',
      'mapTitle': 'Map',
      'currentLocation': 'Current location',
      'assistantTitle': 'Your AI assistant',
      'assistantHint': 'Type your question...',
      'assistantStartNew': 'Choose an area from scratch',
      'assistantOwnAddress': 'I have my own address',
      'assistantBusinessQuestion': 'Great! Which business area interests you?',
      'assistantFood': 'Food service',
      'assistantRetail': 'Retail',
      'assistantBeauty': 'Beauty',
      'assistantOther': '+ Other',
      'menu': 'Menu',
      'assistantSend': 'Send',
      'profileHeader': 'Profile',
      'logout': 'Log out',
      'logoutConfirm': 'Do you want to log out?',
      'cancel': 'Cancel',
      'deleteAudit': 'Delete audit',
      'deleteAuditConfirm': 'Do you want to delete this saved audit?',
      'demoAccountHeader': 'Demo account details',
      'demoPagesHeader': 'Demo pages',
      'dashboardSubtitle': 'A clear view of your account and next steps.',
      'todayAtAGlance': 'Today at a glance',
      'quickActions': 'Quick actions',
      'businessPulse': 'Business pulse',
      'businessPulseValue': '3 ideas ready',
      'businessPulseSubtitle': 'Local trends look promising',
      'clientFocus': 'Client focus',
      'clientFocusValue': '2 priority tasks',
      'clientFocusSubtitle': 'Check today',
      'aiHelp': 'AI help',
      'aiHelpValue': 'Ask anything',
      'aiHelpSubtitle': 'Market, pricing and sales',
      'openAssistant': 'Open assistant',
      'reviewNotifications': 'Review notifications',
      'mapSubtitle': 'Kazakhstan regions and business opportunities',
      'mapCities': 'Astana, Almaty, Shymkent, Aktau',
      'mapDetail': 'A quick view of business opportunities and regional growth',
      'assistantSubtitle':
          'Get help with business ideas, market checks and next steps.',
      'profileSubtitle': 'Manage notifications, language and account settings.',
      'entrepreneur': 'Entrepreneur',
      'planPro': 'Plan: Pro',
      'savedAudits': 'MY SAVED AUDITS',
      'settingsTitle': 'SETTINGS',
      'savedAudit1': 'Aktau, 14th microdistrict',
      'savedAudit2': 'Aktau, Samal',
      'savedAudit3': 'Aktau, 3rd microdistrict',
      'auditDate1': 'Analysis from Aug 18, 2026',
      'auditDate2': 'Analysis from Aug 12, 2026',
      'auditDate3': 'Analysis from Aug 05, 2026',
      'newCompetitors': 'New competitors',
      'notifyCompetitors': 'Notify about nearby openings',
      'auditStatus': 'Ready',
      'noAudits': 'No audits yet',
      'profileName': 'Name',
      'profilePhone': 'Phone',
      'profileLanguage': 'Language',
      'profileTheme': 'Theme',
      'profileOtpDelivery': 'OTP delivery',
      'notificationsTitle': 'Notifications',
      'toggleTheme': 'Toggle theme',
      'receiveOtpVia': 'Receive OTP via',
      'enterUsernamePassword': 'Enter your username and password',
      'languageSettings': 'Language settings',
      'themeSettings': 'Theme settings',
      'themeDescription': 'Choose light, dark or automatic mode',
      'languageDescription':
          'Interface available in Azerbaijani, English, Russian and Kazakh',
      'dashboardHeroTitle': 'Today’s key actions',
      'dashboardHeroSubtitle': 'A quick view of your main goals for today',
      'dashboardHeroChip': 'New idea ready',
      'dashboardActionTitle': 'Next step',
      'dashboardActionSubtitle': 'Open the assistant with one tap',
      'close': 'Close',
      'openInMaps': 'Get directions',
      'businessHotspot': 'Business opportunity area',
      'noNotifications': 'No new notifications',
      'navDashboard': 'Dashboard',
      'navMap': 'Map',
      'navAssistant': 'Assistant',
      'navProfile': 'Profile',
      'free': 'FREE',
      'nextIdeaTitle':
          'Choose your next location with Tochka.ai without unnecessary risk',
      'nextIdeaSubtitle':
          'Check your idea, budget and region, then compare the strongest 3 locations.',
      'analysisStart': 'How should we start the analysis?',
      'idea': 'Idea',
      'place': 'Location',
      'decision': 'Decision',
      'deepAnalytics': 'Initial deep analytics',
      'viabilityForecast': 'Viability forecast for the first year of operation',
      'riskSimilarBusinesses': '6 similar businesses within a 500 m radius',
      'riskVisibility': 'Check entrance visibility on site',
      'unlockRisks': 'Unlock 2 critical risks and the full calculation',
      'calculatorTitle': 'Break-even calculator',
      'monthlyRent': 'Monthly rent (₸)',
      'averageTicket': 'Average ticket (₸)',
      'calculate': 'Calculate',
      'customersNeeded':
          'You need approximately {count} customers per day to break even.',
      'plansTitle': 'Tochka.ai plans',
      'planFreeSubtitle': 'Three-factor chat + map + location score',
      'planOneSubtitle': 'Full analysis + PDF + negotiation text',
      'planThreeSubtitle': 'Full analysis with side-by-side comparison',
      'continue': 'Continue',
      'searchAddressHint': 'Search city or address...',
      'search': 'Search',
      'addressNotFound': 'Address not found. Please be more specific.',
      'locationIndex': 'Location index',
      'footTraffic': 'Foot traffic',
      'high': 'High',
      'competitors': 'Competitors (500 m)',
      'competitorList': 'Found competitors',
      'distance': 'Distance',
      'parking': 'Parking',
      'stops': 'Stops',
      'reviews': 'Reviews',
      'traffic': 'Traffic',
      'trafficUnavailable': 'Unavailable',
      'hoursAvailable': 'Hours available',
      'nearestDistance': 'Nearest competitor',
      'analysisUnavailable': '2GIS analysis unavailable',
      'analyzing': 'Analyzing...',
      'locationPassport': 'PDF location passport',
      'whatsappNegotiation': 'WhatsApp negotiation text',
      'stopListening': 'Stop listening',
      'voiceInput': 'Voice input',
      'smsEmailWhatsapp': 'SMS, Email, WhatsApp',
      'languageEnglish': 'English',
      'personaBaba': 'Wise Baba',
      'personaBabaHint': 'Reduces risk',
      'personaMarketer': 'Creative Marketer',
      'personaMarketerHint': 'Helps you stand out',
      'personaAnalyst': 'Strict Analyst',
      'personaAnalystHint': 'Dry numbers and ROI',
      'assistantWelcome':
          'Hello! I will help you find the ideal location for your business. Do you already have a place in mind, or should I choose the best area from scratch?',
    },
    'ru': {
      'appTitle': 'EAI Ассистент',
      'login': 'Войти',
      'register': 'Регистрация',
      'emailOrUsername': 'Электронная почта или имя пользователя',
      'emailAddress': 'Электронная почта',
      'fullName': 'Имя и фамилия',
      'dateOfBirth': 'Дата рождения',
      'selectDate': 'Выберите дату',
      'google': 'Google',
      'apple': 'Apple',
      'or': 'или',
      'aiBackendError': 'Не удалось подключиться к AI-серверу.',
      'liveReportTitle': 'Живой отчёт 2GIS:',
      'liveLocationIndex': 'Индекс места',
      'liveTrafficIndex': 'Индекс пешеходного трафика',
      'liveCompetitors': 'Конкуренты в радиусе 500 м',
      'liveNearest': 'Ближайший конкурент',
      'liveMapHint': 'Точки конкурентов можно увидеть на вкладке «Карта».',
      'invalidEmail': 'Введите корректный адрес электронной почты.',
      'weakPassword': 'Пароль должен содержать минимум 6 символов.',
      'password': 'Пароль',
      'staySignedIn': 'Оставаться в системе',
      'biometricLogin': 'Войти по отпечатку пальца',
      'welcomeBack': 'С возвращением',
      'description':
          'Искусственный интеллект для бизнес-идей, анализа рынка и локальных рекомендаций.',
      'profileHeader': 'Профиль',
      'logout': 'Выйти из аккаунта',
      'logoutConfirm': 'Выйти из аккаунта?',
      'cancel': 'Отмена',
      'deleteAudit': 'Удалить аудит',
      'deleteAuditConfirm': 'Удалить этот сохраненный аудит?',
      'demoAccountHeader': 'Данные демо-аккаунта',
      'demoPagesHeader': 'Демо страницы',
      'dashboardTitle': 'Обзор на сегодня',
      'dashboardSubtitle': 'Чёткий взгляд на ваш аккаунт и следующие шаги.',
      'todayAtAGlance': 'Сегодня в одном обзоре',
      'quickActions': 'Быстрые действия',
      'businessPulse': 'Бизнес-ритм',
      'businessPulseValue': '3 готовые идеи',
      'businessPulseSubtitle': 'Локальные тренды выглядят перспективно',
      'clientFocus': 'Фокус на клиентах',
      'clientFocusValue': '2 приоритетные задачи',
      'clientFocusSubtitle': 'Проверьте сегодня',
      'aiHelp': 'AI-помощь',
      'aiHelpValue': 'Спросите что угодно',
      'aiHelpSubtitle': 'Маркетинг, цены и продвижение',
      'openAssistant': 'Открыть ассистента',
      'reviewNotifications': 'Проверить уведомления',
      'mapTitle': 'Карта',
      'currentLocation': 'Текущее местоположение',
      'mapSubtitle': 'Регионы Казахстана и деловые возможности',
      'mapCities': 'Астана, Алматы, Шымкент, Актау',
      'mapDetail':
          'Быстрый обзор по деловым возможностям и региональному развитию',
      'assistantTitle': 'Ваш AI-ассистент',
      'assistantSubtitle':
          'Получайте помощь по бизнес-идеям, локальным рынкам и следующим шагам.',
      'assistantHint': 'Напишите ваш вопрос...',
      'assistantStartNew': 'Подобрать район с нуля',
      'assistantOwnAddress': 'У меня есть свой адрес',
      'assistantBusinessQuestion': 'Отлично! Какая сфера вас интересует?',
      'assistantFood': 'Общепит',
      'assistantRetail': 'Продукты',
      'assistantBeauty': 'Бьюти',
      'assistantOther': '+ Другое',
      'menu': 'Меню',
      'assistantSend': 'Отправить',
      'profileSubtitle':
          'Управляйте уведомлениями, языком и настройками аккаунта.',
      'entrepreneur': 'Предприниматель',
      'planPro': 'Тариф: Pro',
      'savedAudits': 'МОИ СОХРАНЁННЫЕ АУДИТЫ',
      'settingsTitle': 'НАСТРОЙКИ',
      'savedAudit1': 'Актау, 14 мкр',
      'savedAudit2': 'Актау, Самал',
      'savedAudit3': 'Актау, 3 мкр',
      'auditDate1': 'Анализ от 18 авг 2026',
      'auditDate2': 'Анализ от 12 авг 2026',
      'auditDate3': 'Анализ от 05 авг 2026',
      'newCompetitors': 'Новые конкуренты',
      'notifyCompetitors': 'Уведомлять об открытиях рядом',
      'auditStatus': 'Готов',
      'noAudits': 'Аудитов пока нет',
      'profileName': 'Имя',
      'profilePhone': 'Телефон',
      'profileLanguage': 'Язык',
      'profileTheme': 'Тема',
      'profileOtpDelivery': 'Доставка OTP',
      'notificationsTitle': 'Уведомления',
      'theme': 'Тема',
      'language': 'Язык',
      'toggleTheme': 'Переключить тему',
      'selectLanguage': 'Выберите язык',
      'receiveOtpVia': 'Получать OTP через',
      'enterUsernamePassword': 'Пожалуйста, введите имя пользователя и пароль',
      'haveAccount': 'Есть аккаунт?',
      'needAccount': 'Нужен аккаунт?',
      'continueAsGuest': 'Продолжить как гость',
      'otpMethod': 'Способ входа',
      'phoneOtp': 'Телефон (SMS)',
      'emailOtp': 'Э-почта (OTP)',
      'whatsappOtp': 'WhatsApp (OTP)',
      'languageSettings': 'Настройки языка',
      'themeSettings': 'Настройки темы',
      'themeDescription': 'Выберите светлый, тёмный или автоматический режим',
      'languageDescription':
          'Интерфейс на азербайджанском, русском и казахском',
      'dashboardHeroTitle': 'Ключевые действия дня',
      'dashboardHeroSubtitle': 'Оперативный обзор главных целей дня',
      'dashboardHeroChip': 'Новая идея готова',
      'dashboardActionTitle': 'Следующий шаг',
      'dashboardActionSubtitle': 'Откройте ассистента в один клик',
      'close': 'Закрыть',
      'openInMaps': 'Построить маршрут',
      'businessHotspot': 'Зона деловых возможностей',
      'noNotifications': 'Новых уведомлений нет',
      'navDashboard': 'Главная',
      'navMap': 'Карта',
      'navAssistant': 'ИИ Ассистент',
      'navProfile': 'Профиль',
      'free': 'БЕСПЛАТНО',
      'nextIdeaTitle':
          'Выберите следующую локацию с Tochka.ai без лишнего риска',
      'nextIdeaSubtitle':
          'Проверьте идею, бюджет и регион, затем сравните 3 лучшие локации.',
      'analysisStart': 'Как начнём анализ?',
      'idea': 'Идея',
      'place': 'Место',
      'decision': 'Решение',
      'deepAnalytics': 'Первичная глубокая аналитика',
      'viabilityForecast': 'Прогноз жизнеспособности в первый год работы',
      'riskSimilarBusinesses': '6 похожих бизнесов в радиусе 500 м',
      'riskVisibility': 'Проверьте видимость входа на месте',
      'unlockRisks': 'Открыть 2 критических риска и полный расчёт',
      'calculatorTitle': 'Калькулятор окупаемости',
      'monthlyRent': 'Аренда в месяц (₸)',
      'averageTicket': 'Средний чек (₸)',
      'calculate': 'Рассчитать',
      'customersNeeded':
          'Для выхода в прибыль нужно примерно {count} клиентов в день.',
      'plansTitle': 'Тарифы Tochka.ai',
      'planFreeSubtitle': 'Трёхфакторный чат + карта + оценка места',
      'planOneSubtitle': 'Полный анализ + PDF + текст переговоров',
      'planThreeSubtitle': 'Полный анализ со сравнением рядом',
      'continue': 'Продолжить',
      'searchAddressHint': 'Поиск города или адреса...',
      'search': 'Поиск',
      'addressNotFound': 'Адрес не найден. Уточните запрос.',
      'locationIndex': 'Индекс места',
      'footTraffic': 'Пешеходный трафик',
      'high': 'Высокий',
      'competitors': 'Конкуренты (500 м)',
      'competitorList': 'Найденные конкуренты',
      'distance': 'Расстояние',
      'parking': 'Парковка',
      'stops': 'Остановка',
      'reviews': 'Отзывы',
      'traffic': 'Трафик',
      'trafficUnavailable': 'Нет данных',
      'hoursAvailable': 'Есть график',
      'nearestDistance': 'Ближайший конкурент',
      'analysisUnavailable': 'Анализ 2GIS недоступен',
      'analyzing': 'Анализируется...',
      'locationPassport': 'PDF-паспорт места',
      'whatsappNegotiation': 'Текст переговоров в WhatsApp',
      'stopListening': 'Остановить прослушивание',
      'voiceInput': 'Голосовой ввод',
      'smsEmailWhatsapp': 'SMS, Email, WhatsApp',
      'languageEnglish': 'English',
      'personaBaba': 'Мудрый Баба',
      'personaBabaHint': 'Снижает риски',
      'personaMarketer': 'Креативный маркетолог',
      'personaMarketerHint': 'Помогает выделиться',
      'personaAnalyst': 'Строгий аналитик',
      'personaAnalystHint': 'Точные цифры и ROI',
      'assistantWelcome':
          'Приветствую! Я помогу найти идеальное место для вашего бизнеса. У вас уже есть помещение на примете, или мне подобрать лучший район с нуля?',
    },
    'kk': {
      'appTitle': 'EAI Ассистент',
      'login': 'Кіру',
      'register': 'Тіркелу',
      'emailOrUsername': 'Электрондық пошта немесе пайдаланушы аты',
      'emailAddress': 'Электрондық пошта',
      'fullName': 'Аты-жөні',
      'dateOfBirth': 'Туған күні',
      'selectDate': 'Күнді таңдаңыз',
      'google': 'Google',
      'apple': 'Apple',
      'or': 'немесе',
      'aiBackendError': 'Қазір AI серверіне қосылу мүмкін болмады.',
      'liveReportTitle': 'Нақты 2GIS есебі:',
      'liveLocationIndex': 'Орын индексі',
      'liveTrafficIndex': 'Жаяу жүргінші ағынының индексі',
      'liveCompetitors': '500 м ішіндегі бәсекелестер',
      'liveNearest': 'Ең жақын бәсекелес',
      'liveMapHint': 'Бәсекелестер нүктелерін Карта панелінен көре аласыз.',
      'invalidEmail': 'Дұрыс электрондық пошта енгізіңіз.',
      'weakPassword': 'Құпия сөз кемінде 6 таңбадан тұруы керек.',
      'password': 'Құпия сөз',
      'staySignedIn': 'Кіруді сақтаңыз',
      'biometricLogin': 'Саусақ ізімен кіру',
      'welcomeBack': 'Қош келдіңіз',
      'description':
          'Жасанды интеллект арқылы бизнес идеялар, нарық талдауы және жергілікті ұсыныстар.',
      'profileHeader': 'Профиль',
      'logout': 'Аккаунттан шығу',
      'logoutConfirm': 'Аккаунттан шыққыңыз келе ме?',
      'cancel': 'Бас тарту',
      'deleteAudit': 'Аудитті өшіру',
      'deleteAuditConfirm': 'Бұл сақталған аудитті өшіру керек пе?',
      'demoAccountHeader': 'Демо есеп жазба деректері',
      'demoPagesHeader': 'Демо беттер',
      'dashboardTitle': 'Бүгінгі шолу',
      'dashboardSubtitle': 'Тіркелгіңіз бен кейінгі қадамдарға нақты шолу.',
      'todayAtAGlance': 'Бүгінге шолу',
      'quickActions': 'Жылдам әрекеттер',
      'businessPulse': 'Бизнес ритмі',
      'businessPulseValue': '3 дайын идея',
      'businessPulseSubtitle': 'Жергілікті трендтер перспективалы',
      'clientFocus': 'Клиентке назар',
      'clientFocusValue': '2 басым тапсырма',
      'clientFocusSubtitle': 'Бүгін тексеріңіз',
      'aiHelp': 'AI көмек',
      'aiHelpValue': 'Кез келген нәрсені сұраңыз',
      'aiHelpSubtitle': 'Нарық, баға және өткізу',
      'openAssistant': 'Ассистентті ашу',
      'reviewNotifications': 'Хабарландыруларды тексеру',
      'mapTitle': 'Карта',
      'currentLocation': 'Ағымдағы орналасу',
      'mapSubtitle': 'Қазақстан өңірлері және бизнес мүмкіндіктері',
      'mapCities': 'Астана, Алматы, Шымкент, Ақтау',
      'mapDetail': 'Бизнес мүмкіндіктері мен аймақтық дамуға жылдам шолу',
      'assistantTitle': 'Сіздің AI-ассистентіңіз',
      'assistantSubtitle':
          'Бизнес идеялары, жергілікті нарықтар және кейінгі қадамдар бойынша көмек алыңыз.',
      'assistantHint': 'Сіздің сұрағыңызды жазыңыз...',
      'assistantStartNew': 'Ауданды нөлден таңдау',
      'assistantOwnAddress': 'Менде өз мекенжайым бар',
      'assistantBusinessQuestion': 'Жақсы! Қай бизнес саласы қызықтырады?',
      'assistantFood': 'Қоғамдық тамақтану',
      'assistantRetail': 'Өнімдер',
      'assistantBeauty': 'Сұлулық',
      'assistantOther': '+ Басқа',
      'menu': 'Мәзір',
      'assistantSend': 'Жіберу',
      'profileSubtitle':
          'Хабарландыруларды, тілді және есептік жазба параметрлерін басқарңыз.',
      'entrepreneur': 'Кәсіпкер',
      'planPro': 'Тариф: Pro',
      'savedAudits': 'САҚТАЛҒАН АУДИТТЕРІМ',
      'settingsTitle': 'ПАРАМЕТРЛЕР',
      'savedAudit1': 'Ақтау, 14-шағынаудан',
      'savedAudit2': 'Ақтау, Самал',
      'savedAudit3': 'Ақтау, 3-шағынаудан',
      'auditDate1': '2026 ж. 18 тамыздағы талдау',
      'auditDate2': '2026 ж. 12 тамыздағы талдау',
      'auditDate3': '2026 ж. 05 тамыздағы талдау',
      'newCompetitors': 'Жаңа бәсекелестер',
      'notifyCompetitors': 'Жақын жердегі жаңалықтар туралы хабарлау',
      'auditStatus': 'Дайын',
      'noAudits': 'Әзірге аудит жоқ',
      'profileName': 'Аты',
      'profilePhone': 'Телефон',
      'profileLanguage': 'Тіл',
      'profileTheme': 'Тема',
      'profileOtpDelivery': 'OTP жеткізу',
      'notificationsTitle': 'Хабарландырулар',
      'theme': 'Тема',
      'language': 'Тіл',
      'toggleTheme': 'Теманы ауыстыру',
      'selectLanguage': 'Тілді таңдаңыз',
      'receiveOtpVia': 'OTP-ді қалай алу',
      'enterUsernamePassword': 'Пайдаланушы атын және құпия сөзді енгізіңіз',
      'haveAccount': 'Аккаунт бар ма?',
      'needAccount': 'Аккаунт қажет пе?',
      'continueAsGuest': 'Қонақ ретінде жалғастыру',
      'otpMethod': 'Кіру әдісі',
      'phoneOtp': 'Телефон (SMS)',
      'emailOtp': 'Э-пошта (OTP)',
      'whatsappOtp': 'WhatsApp (OTP)',
      'languageSettings': 'Тіл параметрлері',
      'themeSettings': 'Тема параметрлері',
      'themeDescription': 'Жарық, қараңғы немесе автоматты режимді таңдаңыз',
      'languageDescription': 'Интерфейс азербайжан, орыс және қазақ тілдерінде',
      'dashboardHeroTitle': 'Күннің негізгі әрекеттері',
      'dashboardHeroSubtitle': 'Күннің негізгі мақсаттарына жылдам шолу',
      'dashboardHeroChip': 'Жаңа идея дайын',
      'dashboardActionTitle': 'Келесі қадам',
      'dashboardActionSubtitle': 'Бір шертіп ассистентке өтіңіз',
      'close': 'Жабу',
      'openInMaps': 'Бағыт алу',
      'businessHotspot': 'Бизнес мүмкіндігі аймағы',
      'noNotifications': 'Жаңа хабарландыру жоқ',
      'navDashboard': 'Панель',
      'navMap': 'Карта',
      'navAssistant': 'Ассистент',
      'navProfile': 'Профиль',
      'free': 'ТЕГІН',
      'nextIdeaTitle': 'Tochka.ai көмегімен келесі орынды тәуекелсіз таңдаңыз',
      'nextIdeaSubtitle':
          'Идеяңызды, бюджетіңізді және аймақты тексеріп, ең мықты 3 орынды салыстырыңыз.',
      'analysisStart': 'Талдауды қалай бастаймыз?',
      'idea': 'Идея',
      'place': 'Орын',
      'decision': 'Шешім',
      'deepAnalytics': 'Алғашқы терең аналитика',
      'viabilityForecast': 'Бірінші жұмыс жылына өміршеңдік болжамы',
      'riskSimilarBusinesses': '500 м радиуста 6 ұқсас бизнес бар',
      'riskVisibility': 'Кіреберіс көрінуін орнында тексеріңіз',
      'unlockRisks': '2 маңызды тәуекел мен толық есептеуді ашу',
      'calculatorTitle': 'Өтелімділік калькуляторы',
      'monthlyRent': 'Айлық жалдау (₸)',
      'averageTicket': 'Орташа чек (₸)',
      'calculate': 'Есептеу',
      'customersNeeded':
          'Пайдаға шығу үшін күніне шамамен {count} клиент қажет.',
      'plansTitle': 'Tochka.ai тарифтері',
      'planFreeSubtitle': 'Үш факторлы чат + карта + орын бағасы',
      'planOneSubtitle': 'Толық талдау + PDF + келіссөз мәтіні',
      'planThreeSubtitle': 'Қатар салыстырумен толық талдау',
      'continue': 'Жалғастыру',
      'searchAddressHint': 'Қала немесе мекенжай іздеу...',
      'search': 'Іздеу',
      'addressNotFound': 'Мекенжай табылмады. Нақтырақ жазыңыз.',
      'locationIndex': 'Орын индексі',
      'footTraffic': 'Жаяу жүргінші трафигі',
      'high': 'Жоғары',
      'competitors': 'Бәсекелестер (500 м)',
      'competitorList': 'Табылған бәсекелестер',
      'distance': 'Қашықтық',
      'parking': 'Тұрақ',
      'stops': 'Аялдама',
      'reviews': 'Пікір',
      'traffic': 'Трафик',
      'trafficUnavailable': 'Дерек жоқ',
      'hoursAvailable': 'Кесте бар',
      'nearestDistance': 'Ең жақын бәсекелес',
      'analysisUnavailable': '2GIS талдауы қолжетімсіз',
      'analyzing': 'Талдануда...',
      'locationPassport': 'PDF орын паспорты',
      'whatsappNegotiation': 'WhatsApp келіссөз мәтіні',
      'stopListening': 'Тыңдауды тоқтату',
      'voiceInput': 'Дауыспен енгізу',
      'smsEmailWhatsapp': 'SMS, Email, WhatsApp',
      'languageEnglish': 'English',
      'personaBaba': 'Дана Баба',
      'personaBabaHint': 'Тәуекелді азайтады',
      'personaMarketer': 'Креативті маркетолог',
      'personaMarketerHint': 'Ерекшеленуге көмектеседі',
      'personaAnalyst': 'Қатаң аналитик',
      'personaAnalystHint': 'Нақты сандар және ROI',
      'assistantWelcome':
          'Сәлеметсіз бе! Бизнесіңізге мінсіз орын табуға көмектесемін. Сізде дайын нысан бар ма, әлде ең жақсы ауданды нөлден таңдап берейін бе?',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<AppLocalizations>();
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['az']![key] ??
        key;
  }

  static String translate(String localeCode, String key) {
    return _localizedValues[localeCode]?[key] ??
        _localizedValues['az']![key] ??
        key;
  }

  @override
  bool updateShouldNotify(covariant AppLocalizations oldWidget) =>
      oldWidget.locale != locale;
}

class AiBusinessAgentApp extends StatefulWidget {
  const AiBusinessAgentApp({super.key});

  @override
  State<AiBusinessAgentApp> createState() => _AiBusinessAgentAppState();
}

class _AiBusinessAgentAppState extends State<AiBusinessAgentApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('az');

  @override
  void initState() {
    super.initState();
    final phoneLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (const {'az', 'en', 'ru', 'kk'}.contains(phoneLanguage)) {
      _locale = Locale(phoneLanguage);
    }
  }

  Locale _materialLocaleFor(Locale locale) {
    final supportedCodes = {'az', 'en', 'ru', 'kk'};
    return supportedCodes.contains(locale.languageCode)
        ? locale
        : const Locale('en');
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  void _updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLocalizations(
      locale: _locale,
      child: MaterialApp(
        title: AppLocalizations.translate(_locale.languageCode, 'appTitle'),
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        supportedLocales: const [
          Locale('az'),
          Locale('en'),
          Locale('ru'),
          Locale('kk'),
        ],
        locale: _materialLocaleFor(_locale),
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) return const Locale('en');
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
          return const Locale('en');
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: HomeShell(
          onToggleTheme: _toggleTheme,
          onLocaleChanged: _updateLocale,
          currentLocaleCode: _locale.languageCode,
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      textTheme: base.textTheme.apply(
        fontSizeFactor: 1.0,
        bodyColor: isDark
            ? Colors.white.withValues(alpha: 0.92)
            : const Color(0xFF1B1E28),
        displayColor: isDark ? Colors.white : const Color(0xFF1B1E28),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1B1E28),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1B1E28),
        ),
      ),
      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        color: isDark ? const Color(0xFF141B2E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE7E9F3),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF2F3FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1626) : Colors.white,
        elevation: 0,
        height: 68,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? scheme.primary
                : (isDark ? Colors.white60 : Colors.black54),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? scheme.primary
                : (isDark ? Colors.white60 : Colors.black45),
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE7E9F3),
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

class LocationAnalysisController extends ChangeNotifier {
  final BusinessApiService _service = BusinessApiService();
  Map<String, dynamic>? analysis;
  bool isAnalyzing = false;
  String mapProvider = ApiConfig.mapsProvider;

  void setMapProvider(String provider) {
    mapProvider = provider;
    notifyListeners();
  }

  void restoreAnalysis(Map<String, dynamic> savedAnalysis) {
    analysis = savedAnalysis;
    notifyListeners();
  }

  void clearAnalysis() {
    analysis = null;
    notifyListeners();
  }

  Future<void> analyze({
    required String city,
    required String businessType,
    String address = '',
  }) async {
    isAnalyzing = true;
    notifyListeners();
    try {
      analysis = await _service.analyze2GisLocation(
        city: city,
        businessType: businessType,
        address: address,
        mapProvider: mapProvider,
      );
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> analyzeFromPrompt(String prompt) async {
    final normalized = prompt.toLowerCase();
    const locationSignals = [
      'məkan',
      'ünvan',
      'şəhər',
      'biznes',
      'kafe',
      'restoran',
      'rəqib',
      'trafik',
      'место',
      'адрес',
      'город',
      'бизнес',
      'кафе',
      'конкурент',
      'трафик',
      'орын',
      'қала',
      'бәсекелес',
    ];
    if (!locationSignals.any(normalized.contains)) return;

    const cities = ['Astana', 'Almaty', 'Shymkent', 'Aktau'];
    final city = cities.firstWhere(
      (item) => normalized.contains(item.toLowerCase()),
      orElse: () => prompt.trim(),
    );
    try {
      await analyze(city: city, businessType: prompt, address: prompt);
    } catch (_) {
      // Chat remains usable when a free-form prompt is not a 2GIS address.
    }
  }

  Map<String, dynamic>? get contextForAi => analysis;
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.onToggleTheme,
    required this.onLocaleChanged,
    required this.currentLocaleCode,
  });

  final VoidCallback onToggleTheme;
  final ValueChanged<Locale> onLocaleChanged;
  final String currentLocaleCode;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final LocationAnalysisController _locationController =
      LocationAnalysisController();
  final AuditHistoryService _auditHistoryService = AuditHistoryService();
  List<Map<String, dynamic>> _auditHistory = [];
  int _selectedIndex = 0;
  bool _authenticated = false;
  bool _checkingSession = false;
  bool _canBiometricLogin = false;
  Map<String, dynamic>? _savedUser;
  final MongoAuthService _authService = MongoAuthService();
  final BiometricAuthService _biometricService = BiometricAuthService();
  Map<String, dynamic>? _currentUser;
  bool _showNotifications = false;
  int? _activeFlow;
  String _auditAddress = '';

  final List<String> _notifications = const [
    'Yeni sınaq bildirişi: hesabınız uğurla yaradıldı.',
    'Aşağıdakı AI tapşırığınız üçün təklif hazırdır.',
    'Demo bildiriş: yeni şablon əlavə edildi.',
  ];

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _loadAuditHistory();
  }

  Future<void> _loadAuditHistory() async {
    final history = await _auditHistoryService.load();
    if (!mounted) return;
    final processedHistory = history.map((item) {
      final analysis = item['analysis'] is Map
          ? Map<String, dynamic>.from(item['analysis'] as Map)
          : <String, dynamic>{};
      final address = (item['address'] ?? analysis['address'] ?? '').toString();
      final createdAt = item['createdAt']?.toString() ?? '';
      return {
        ...item,
        'displayAddress': address,
        'displayDate': _formatAuditDate(createdAt),
        'status': 'Hazır',
      };
    }).toList();
    setState(() => _auditHistory = processedHistory);
  }

  String _formatAuditDate(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      if (difference.inDays == 0) return 'Bugün $time';
      if (difference.inDays == 1) return 'Dünən $time';
      if (difference.inDays < 7) {
        const days = [
          'Bazar ertəsi',
          'Çərşənbə axşamı',
          'Çərşənbə',
          'Cümə axşamı',
          'Cümə',
          'Şənbə',
          'Bazar',
        ];
        return '${days[date.weekday - 1]} $time';
      }
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return createdAt;
    }
  }

  Future<void> _saveAudit(String address, String businessType) async {
    final result = _locationController.analysis;
    if (result == null) return;
    final actualAddress = (result['address'] ?? address).toString();
    await _auditHistoryService.add(
      analysis: result,
      address: actualAddress,
      businessType: businessType,
    );
    await _loadAuditHistory();
  }

  Future<void> _deleteAudit(Map<String, dynamic> audit) async {
    final id = audit['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _auditHistoryService.remove(id);
    await _loadAuditHistory();
  }

  void _openSavedAudit(Map<String, dynamic> item) {
    final saved = item['analysis'];
    if (saved is! Map) return;
    final savedAnalysis = Map<String, dynamic>.from(saved);
    final savedAddress = (savedAnalysis['address'] ?? item['address'] ?? '')
        .toString()
        .trim();
    final savedBusiness =
        (item['businessType'] ?? savedAnalysis['business_query'] ?? 'business')
            .toString();
    setState(() {
      _locationController.restoreAnalysis(savedAnalysis);
      _auditAddress = savedAddress;
      _selectedIndex = 1;
      _activeFlow = null;
    });
    _refreshSavedAudit(savedAddress, savedBusiness, savedAnalysis);
  }

  Future<void> _refreshSavedAudit(
    String address,
    String businessType,
    Map<String, dynamic> fallback,
  ) async {
    if (address.isEmpty) return;
    try {
      await _locationController.analyze(
        city: address,
        businessType: businessType,
        address: address,
      );
      await _saveAudit(address, businessType);
      if (mounted) {
        setState(() {
          _auditAddress = (_locationController.analysis?['address'] ?? address)
              .toString();
        });
      }
    } catch (_) {
      // Keep the saved snapshot visible when the network is unavailable.
      _locationController.restoreAnalysis(fallback);
    }
  }

  Future<void> _restoreSession() async {
    final user = await _authService.restoreSession();
    final biometricEnabled =
        user != null && await _authService.biometricEnabled;
    if (!mounted) return;
    if (user != null && biometricEnabled) {
      setState(() {
        _savedUser = user;
        _canBiometricLogin = true;
        _checkingSession = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _unlockWithBiometric(),
      );
    } else if (user != null) {
      _completeAuthentication(user);
    } else {
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _unlockWithBiometric() async {
    final user = _savedUser;
    if (user == null || !await _biometricService.authenticate()) return;
    _completeAuthentication(user);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _currentUser = null;
      _savedUser = null;
      _activeFlow = null;
      _selectedIndex = 0;
    });
  }

  void _completeAuthentication(Map<String, dynamic> user) {
    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _currentUser = user;
      _savedUser = user;
      _selectedIndex = 0;
      _activeFlow = null;
      _checkingSession = false;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _openAppMenu() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(loc.t('toggleTheme')),
              onTap: () {
                Navigator.pop(context);
                widget.onToggleTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(loc.t('selectLanguage')),
              onTap: () {
                Navigator.pop(context);
                showDialog<String>(
                  context: this.context,
                  builder: (context) => SimpleDialog(
                    title: Text(loc.t('selectLanguage')),
                    children: [
                      SimpleDialogOption(
                        child: const Text('Azərbaycan'),
                        onPressed: () => Navigator.pop(context, 'az'),
                      ),
                      SimpleDialogOption(
                        child: const Text('English'),
                        onPressed: () => Navigator.pop(context, 'en'),
                      ),
                      SimpleDialogOption(
                        child: const Text('Русский'),
                        onPressed: () => Navigator.pop(context, 'ru'),
                      ),
                      SimpleDialogOption(
                        child: const Text('Қазақша'),
                        onPressed: () => Navigator.pop(context, 'kk'),
                      ),
                    ],
                  ),
                ).then((value) {
                  if (value is String) widget.onLocaleChanged(Locale(value));
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: loc.t('navDashboard'),
      ),
      _NavItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map,
        label: loc.t('navMap'),
      ),
      _NavItem(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        label: loc.t('navAssistant'),
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: loc.t('navProfile'),
      ),
    ];

    return Scaffold(
      appBar: _authenticated && _activeFlow == null
          ? AppBar(
              leading: IconButton(
                tooltip: loc.t('menu'),
                onPressed: _openAppMenu,
                icon: const Icon(Icons.menu),
              ),
              centerTitle: true,
              title: Text(loc.t('appTitle')),
              actions: [
                IconButton(
                  tooltip: loc.t('notificationsTitle'),
                  onPressed: () =>
                      setState(() => _showNotifications = !_showNotifications),
                  icon: Badge(
                    isLabelVisible: _notifications.isNotEmpty,
                    smallSize: 8,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: Stack(
        children: [
          if (_checkingSession)
            const Center(child: CircularProgressIndicator())
          else if (!_authenticated)
            AuthScreen(
              onAuthenticated: _completeAuthentication,
              onBiometricAuthenticated: _unlockWithBiometric,
              showBiometricButton: _canBiometricLogin,
              onLocaleChanged: widget.onLocaleChanged,
              currentLocaleCode: widget.currentLocaleCode,
            ),
          if (_authenticated && _activeFlow == null)
            IndexedStack(
              index: _selectedIndex,
              children: [
                ProductDashboardScreen(
                  localeCode: widget.currentLocaleCode,
                  audits: _auditHistory,
                  onAuditSelected: _openSavedAudit,
                  onAuditDeleted: _deleteAudit,
                  mapProvider: _locationController.mapProvider,
                  onMapProviderChanged: (provider) => setState(
                    () => _locationController.setMapProvider(provider),
                  ),
                  onOldPoint: () => setState(() => _activeFlow = 1),
                  onNewPoint: () => setState(() => _activeFlow = 2),
                ),
                MapScreen(controller: _locationController),
                ChatScreen(controller: _locationController),
                ProfileScreen(
                  user: _currentUser,
                  onLocaleChanged: widget.onLocaleChanged,
                  currentLocaleCode: widget.currentLocaleCode,
                  onToggleTheme: widget.onToggleTheme,
                  onLogout: _logout,
                  audits: _auditHistory,
                  onAuditSelected: _openSavedAudit,
                  onAuditDeleted: _deleteAudit,
                  mapProvider: _locationController.mapProvider,
                  onMapProviderChanged: (provider) => setState(
                    () => _locationController.setMapProvider(provider),
                  ),
                ),
              ],
            ),
          if (_authenticated && _activeFlow == 1)
            OldPointSurveyScreen(
              localeCode: widget.currentLocaleCode,
              onBack: () => setState(() => _activeFlow = null),
              onAudit: _runAudit,
            ),
          if (_authenticated && _activeFlow == 2)
            NewPointAssistantScreen(
              localeCode: widget.currentLocaleCode,
              onBack: () => setState(() => _activeFlow = null),
              onAnalyze: _runChatLocationAnalysis,
              onMap: () => setState(() {
                _activeFlow = null;
                _selectedIndex = 1;
              }),
            ),
          if (_authenticated && _activeFlow == 3)
            AuditReportScreen(
              localeCode: widget.currentLocaleCode,
              analysis: _locationController.analysis,
              address: _auditAddress,
              onBack: () => setState(() => _activeFlow = 1),
              onMap: () => setState(() {
                _activeFlow = null;
                _selectedIndex = 1;
              }),
            ),
          if (_showNotifications)
            _NotificationsOverlay(
              notifications: _notifications,
              onClose: () => setState(() => _showNotifications = false),
            ),
        ],
      ),
      bottomNavigationBar: _authenticated && _activeFlow == null
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF18181B),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFA855F7),
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() {
                _selectedIndex = index;
                _activeFlow = null;
                _showNotifications = false;
              }),
              items: navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  Future<Map<String, dynamic>?> _runAudit({
    required String businessType,
    required List<String> problems,
    required String address,
  }) async {
    await _locationController.analyze(
      city: address,
      businessType:
          '$businessType${problems.isEmpty ? '' : ' — ${problems.join(', ')}'}',
      address: address,
    );
    await _saveAudit(address, businessType);
    if (!mounted) return _locationController.analysis;
    setState(() {
      _auditAddress = (_locationController.analysis?['address'] ?? address)
          .toString();
      _activeFlow = 3;
    });
    return _locationController.analysis;
  }

  Future<void> _runChatLocationAnalysis(
    String businessType,
    String address,
  ) async {
    await _locationController.analyze(
      city: address,
      businessType: businessType,
      address: address,
    );
    await _saveAudit(address, businessType);
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NotificationsOverlay extends StatelessWidget {
  const _NotificationsOverlay({
    required this.notifications,
    required this.onClose,
  });

  final List<String> notifications;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          top: AppSpacing.sm,
          child: Material(
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: Theme.of(context).cardTheme.color,
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.t('notificationsTitle'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        loc.t('noNotifications'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) => ListTile(
                          dense: true,
                          leading: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            notifications[index],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openWhatsApp(String address) async {
  final text = Uri.encodeComponent(
    'Salam. $address məkanı ilə maraqlanıram. Rəqib sıxlığı və giriş görünürlüğünü nəzərə alaraq icarə qiymətində güzəşt müzakirə edə bilərikmi?',
  );
  final uri = Uri.parse('https://wa.me/?text=$text');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ============================================================
// AUTH
// ============================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    required this.onLocaleChanged,
    required this.currentLocaleCode,
    this.onBiometricAuthenticated,
    this.showBiometricButton = false,
  });

  final ValueChanged<Map<String, dynamic>> onAuthenticated;
  final ValueChanged<Locale> onLocaleChanged;
  final String currentLocaleCode;
  final Future<void> Function()? onBiometricAuthenticated;
  final bool showBiometricButton;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _staySignedIn = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _useBiometric = false;
  DateTime? _dateOfBirth;
  final MongoAuthService _authService = MongoAuthService();
  final SocialAuthService _socialAuthService = SocialAuthService();
  final BiometricAuthService _biometricService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _biometricService.isAvailable().then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    if (_isRegister && name.length < 3) {
      _showError('Ad və soyad daxil edin.');
      return;
    }
    if (_isRegister && phone.length < 7) {
      _showError('Düzgün mobil nömrə daxil edin.');
      return;
    }
    if (_isRegister && _dateOfBirth == null) {
      _showError('Doğum tarixini seçin.');
      return;
    }
    if (!email.contains('@')) {
      _showError(AppLocalizations.of(context).t('invalidEmail'));
      return;
    }
    if (pass.length < 6) {
      _showError(AppLocalizations.of(context).t('weakPassword'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isRegister) {
        final user = await _authService.signUp(
          name: name,
          email: email,
          password: pass,
          phone: phone,
          dateOfBirth: _dateOfBirth,
        );
        if (mounted) widget.onAuthenticated(user);
      } else {
        final user = await _authService.login(email: email, password: pass);
        if (_biometricAvailable) {
          await _authService.setBiometricEnabled(_useBiometric);
        }
        if (mounted) widget.onAuthenticated(user);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        content: Text(message),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: AppLocalizations.of(context).t('dateOfBirth'),
    );
    if (selected != null) setState(() => _dateOfBirth = selected);
  }

  Future<void> _socialSignIn({required bool apple}) async {
    setState(() => _isLoading = true);
    try {
      final user = apple
          ? await _socialAuthService.signInWithApple()
          : await _socialAuthService.signInWithGoogle();
      if (mounted) widget.onAuthenticated(user);
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: PopupMenuButton<String>(
                      tooltip: loc.t('selectLanguage'),
                      icon: const Icon(Icons.language_outlined),
                      onSelected: (value) =>
                          widget.onLocaleChanged(Locale(value)),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'az', child: Text('Azərbaycan')),
                        PopupMenuItem(value: 'en', child: Text('English')),
                        PopupMenuItem(value: 'ru', child: Text('Русский')),
                        PopupMenuItem(value: 'kk', child: Text('Қазақша')),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.translate(
                      loc.locale.languageCode,
                      'appTitle',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.t('description'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.outline, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SegmentedTabs(
                            isRegister: _isRegister,
                            loginLabel: loc.t('login'),
                            registerLabel: loc.t('register'),
                            onChanged: (v) => setState(() => _isRegister = v),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _socialSignIn(apple: false),
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: Text(loc.t('google')),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _socialSignIn(apple: true),
                                  icon: const Icon(Icons.apple),
                                  label: Text(loc.t('apple')),
                                ),
                              ),
                            ],
                          ),
                          if (_biometricAvailable && !_isRegister)
                            Row(
                              children: [
                                Checkbox(
                                  value: _useBiometric,
                                  onChanged: (value) => setState(
                                    () => _useBiometric = value ?? false,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Expanded(
                                  child: Text(
                                    loc.t('biometricLogin'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  loc.t('or'),
                                  style: TextStyle(color: scheme.outline),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_isRegister) ...[
                            TextField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: loc.t('fullName'),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: loc.t('profilePhone'),
                                hintText: '+994 50 123 45 67',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            InkWell(
                              onTap: _isLoading ? null : _selectDateOfBirth,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: loc.t('dateOfBirth'),
                                  prefixIcon: Icon(Icons.cake_outlined),
                                ),
                                child: Text(
                                  _dateOfBirth == null
                                      ? loc.t('selectDate')
                                      : '${_dateOfBirth!.day.toString().padLeft(2, '0')}.${_dateOfBirth!.month.toString().padLeft(2, '0')}.${_dateOfBirth!.year}',
                                  style: TextStyle(
                                    color: _dateOfBirth == null
                                        ? scheme.outline
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: loc.t('emailAddress'),
                              hintText: 'example@mail.com',
                              prefixIcon: const Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: loc.t('password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Checkbox(
                                value: _staySignedIn,
                                onChanged: (v) =>
                                    setState(() => _staySignedIn = v ?? false),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  loc.t('staySignedIn'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            key: const Key('login_button'),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegister
                                        ? loc.t('register')
                                        : loc.t('login'),
                                  ),
                          ),
                          if (widget.showBiometricButton &&
                              widget.onBiometricAuthenticated != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : widget.onBiometricAuthenticated,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(loc.t('biometricLogin')),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isRegister = !_isRegister),
                              child: Text(
                                _isRegister
                                    ? loc.t('haveAccount')
                                    : loc.t('needAccount'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.isRegister,
    required this.loginLabel,
    required this.registerLabel,
    required this.onChanged,
  });

  final bool isRegister;
  final String loginLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF2F3FA),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: loginLabel,
              selected: !isRegister,
              color: scheme.primary,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: registerLabel,
              selected: isRegister,
              color: scheme.primary,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm - 4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final cards = [
      _SummaryCard(
        icon: Icons.trending_up_rounded,
        iconColor: scheme.primary,
        title: loc.t('businessPulse'),
        value: loc.t('businessPulseValue'),
        subtitle: loc.t('businessPulseSubtitle'),
      ),
      _SummaryCard(
        icon: Icons.flag_outlined,
        iconColor: AppColors.secondary,
        title: loc.t('clientFocus'),
        value: loc.t('clientFocusValue'),
        subtitle: loc.t('clientFocusSubtitle'),
      ),
      _SummaryCard(
        icon: Icons.psychology_outlined,
        iconColor: const Color(0xFFF59E0B),
        title: loc.t('aiHelp'),
        value: loc.t('aiHelpValue'),
        subtitle: loc.t('aiHelpSubtitle'),
      ),
    ];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _HeroBanner(loc: loc, scheme: scheme),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.t('nextIdeaTitle'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      Icons.lock_outline,
                      size: 15,
                      color: scheme.primary,
                    ),
                    label: Text(loc.t('free')),
                    side: BorderSide.none,
                    backgroundColor: scheme.primary.withValues(alpha: 0.10),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.t('nextIdeaSubtitle'),
                style: TextStyle(color: scheme.outline, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('analysisStart'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _MiniStep(
                            number: '1',
                            label: loc.t('idea'),
                            color: scheme.primary,
                          ),
                          _StepLine(color: scheme.primary),
                          _MiniStep(
                            number: '2',
                            label: loc.t('place'),
                            color: AppColors.secondary,
                          ),
                          _StepLine(color: AppColors.secondary),
                          _MiniStep(
                            number: '3',
                            label: loc.t('decision'),
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.t('todayAtAGlance'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.t('dashboardSubtitle'),
                style: TextStyle(color: scheme.outline),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: isWide ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // A taller mobile card prevents the subtitle from overflowing
                // by a few pixels on narrow screens.
                childAspectRatio: isWide ? 1.35 : 2.15,
                children: cards,
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.t('deepAnalytics'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '68%',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.t('viabilityForecast'),
                        style: TextStyle(color: scheme.outline, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: .68,
                          minHeight: 9,
                          color: AppColors.secondary,
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: .12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RiskRow(
                        icon: Icons.warning_amber_rounded,
                        text: loc.t('riskSimilarBusinesses'),
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 8),
                      _RiskRow(
                        icon: Icons.visibility_outlined,
                        text: loc.t('riskVisibility'),
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showPlans(context),
                        icon: const Icon(Icons.lock_open_outlined, size: 17),
                        label: Text(loc.t('unlockRisks')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('quickActions'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _QuickActionTile(
                        icon: Icons.chat_bubble_outline,
                        color: scheme.primary,
                        title: loc.t('openAssistant'),
                        subtitle: loc.t('dashboardActionSubtitle'),
                        onTap: () => _showRoiCalculator(context),
                      ),
                      const Divider(height: AppSpacing.lg),
                      _QuickActionTile(
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.secondary,
                        title: loc.t('reviewNotifications'),
                        subtitle: loc.t('dashboardActionSubtitle'),
                        onTap: () => _showPlans(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({
    required this.number,
    required this.label,
    required this.color,
  });
  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            number,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: color.withValues(alpha: 0.25),
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.loc, required this.scheme});

  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: [scheme.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            avatar: const Icon(Icons.bolt, size: 16, color: Colors.white),
            label: Text(
              loc.t('dashboardHeroChip'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            loc.t('dashboardHeroTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.t('dashboardHeroSubtitle'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Summary cards use a clean surface; the global card outline looked
      // like an unrelated progress/divider line beneath each metric.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

void _showRoiCalculator(BuildContext context) {
  final loc = AppLocalizations.of(context);
  final rent = TextEditingController(text: '800000');
  final ticket = TextEditingController(text: '3500');
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(loc.t('calculatorTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: rent,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: loc.t('monthlyRent')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ticket,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: loc.t('averageTicket')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(loc.t('close')),
        ),
        FilledButton(
          onPressed: () {
            final monthlyRent = double.tryParse(rent.text) ?? 0;
            final averageTicket = double.tryParse(ticket.text) ?? 0;
            final customers = averageTicket == 0
                ? 0
                : (monthlyRent / .35 / averageTicket).ceil();
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  loc
                      .t('customersNeeded')
                      .replaceFirst('{count}', '${((customers / 30).ceil())}'),
                ),
              ),
            );
          },
          child: Text(loc.t('calculate')),
        ),
      ],
    ),
  ).whenComplete(() {
    rent.dispose();
    ticket.dispose();
  });
}

void _showPlans(BuildContext context) {
  final loc = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('plansTitle'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.lock_open),
              title: Text(loc.t('free')),
              subtitle: Text(loc.t('planFreeSubtitle')),
              trailing: Text('0 ₸'),
            ),
            ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('1 ${loc.t('place').toUpperCase()}'),
              subtitle: Text(loc.t('planOneSubtitle')),
              trailing: Text('1 990 ₸'),
            ),
            ListTile(
              leading: Icon(Icons.layers_outlined),
              title: Text('3 ${loc.t('place').toUpperCase()}'),
              subtitle: Text(loc.t('planThreeSubtitle')),
              trailing: Text('4 900 ₸'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.t('continue')),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// MAP  — real, free OpenStreetMap tiles via flutter_map.
// (Add to pubspec.yaml: flutter_map + latlong2 — see notes below.)
// ============================================================
class _CityPin {
  const _CityPin({required this.name, required this.point});
  final String name;
  final LatLng point;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.controller});

  final LocationAnalysisController controller;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  static final List<_CityPin> _cities = [
    _CityPin(name: 'Astana', point: const LatLng(51.1605, 71.4704)),
    _CityPin(name: 'Almaty', point: const LatLng(43.2220, 76.8512)),
    _CityPin(name: 'Shymkent', point: const LatLng(42.3417, 69.5901)),
    _CityPin(name: 'Aktau', point: const LatLng(43.6500, 51.1600)),
  ];

  static const LatLng _kazakhstanCenter = LatLng(48.0196, 66.9237);

  _CityPin? _selected;
  _CityPin? _customPin;
  String _search = '';
  bool _isSearching = false;
  String? _lastAnalysisUpdate;
  LatLng? _pendingAnalysisPoint;
  bool _locatingDevice = false;
  bool _showMapInfo = true;

  List<_CityPin> get _visibleCities => _cities
      .where((city) => city.name.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _locateDevice();
  }

  Future<void> _locateDevice({bool clearAnalysis = false}) async {
    // Opening the map after an audit must keep that audit visible. The
    // analysis is cleared only when the user explicitly asks for GPS location.
    if (!clearAnalysis) {
      final existingPoint = _analysisPoint(widget.controller.analysis);
      if (existingPoint != null) {
        final existingAddress =
            (widget.controller.analysis?['address'] ??
                    AppLocalizations.of(context).t('mapTitle'))
                .toString();
        if (mounted) {
          setState(() {
            _customPin = _CityPin(name: existingAddress, point: existingPoint);
            _selected = _customPin;
          });
        }
        try {
          _mapController.move(existingPoint, 15);
        } catch (_) {
          _pendingAnalysisPoint = existingPoint;
        }
        return;
      }
    }
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    if (mounted) setState(() => _locatingDevice = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final pin = _CityPin(
        name: AppLocalizations.of(context).t('currentLocation'),
        point: LatLng(position.latitude, position.longitude),
      );
      if (!mounted) return;
      setState(() {
        _customPin = pin;
        _selected = pin;
      });
      if (clearAnalysis && widget.controller.analysis != null) {
        widget.controller.clearAnalysis();
      }
      try {
        _mapController.move(pin.point, 14.5);
      } catch (_) {
        _pendingAnalysisPoint = pin.point;
      }
    } catch (_) {
      // Location is optional; the map remains usable without permission.
    } finally {
      if (mounted) setState(() => _locatingDevice = false);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final analysis = widget.controller.analysis;
    final updatedAt = analysis?['updated_at']?.toString();
    final point = _analysisPoint(analysis);
    final analysisToken = updatedAt ?? point?.toString();
    if (point != null &&
        analysisToken != null &&
        analysisToken != _lastAnalysisUpdate) {
      _lastAnalysisUpdate = analysisToken;
      _pendingAnalysisPoint = point;
      _customPin = _CityPin(
        name:
            (analysis?['address'] ?? AppLocalizations.of(context).t('mapTitle'))
                .toString(),
        point: point,
      );
      _selected = _customPin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moveToPendingAnalysis();
      });
    }
    setState(() {});
  }

  void _moveToPendingAnalysis() {
    final point =
        _pendingAnalysisPoint ?? _analysisPoint(widget.controller.analysis);
    if (!mounted || point == null) return;
    try {
      _mapController.move(point, 15);
      _pendingAnalysisPoint = null;
    } catch (_) {
      // FlutterMap may not be attached yet; onMapReady retries the move.
    }
  }

  LatLng? _analysisPoint(Map<String, dynamic>? analysis) {
    final raw = analysis?['point'];
    if (raw is! Map) return null;
    final lat = double.tryParse(raw['lat']?.toString() ?? '');
    final lon = double.tryParse(raw['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _focusCity(_CityPin city) async {
    setState(() => _selected = city);
    _mapController.move(city.point, 6.2);
    await _refreshAnalysis(city);
  }

  Future<void> _refreshAnalysis(_CityPin pin) async {
    try {
      await widget.controller.analyze(
        city: pin.name,
        businessType: 'business',
        address: pin.name,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('analysisUnavailable')),
        ),
      );
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      // Search and geocode through the backend's 2GIS Catalog API first.
      // This keeps the selected address and the map marker in the same source.
      await widget.controller.analyze(
        city: query,
        businessType: 'business',
        address: query,
      );
      final analysis = widget.controller.analysis;
      final point = _analysisPoint(analysis);
      if (point != null) {
        final pin = _CityPin(
          name: (analysis?['address'] ?? query).toString(),
          point: point,
        );
        if (!mounted) return;
        setState(() {
          _customPin = pin;
          _selected = pin;
          _showMapInfo = true;
        });
        _mapController.move(point, 16);
        return;
      }
      throw Exception('2GIS address not found');
    } catch (_) {
      // Keep OSM as a fallback when the backend/key is unavailable.
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': query,
          'format': 'jsonv2',
          'limit': '1',
        });
        final response = await http
            .get(
              uri,
              headers: {
                'User-Agent': 'AI-Business-Agent/1.0 (address search)',
                'Accept-Language': 'az,en',
              },
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) throw Exception('Search failed');
        final results = jsonDecode(response.body) as List<dynamic>;
        if (results.isEmpty) throw Exception('Address not found');
        final result = results.first as Map<String, dynamic>;
        final lat = double.parse(result['lat'].toString());
        final lon = double.parse(result['lon'].toString());
        final pin = _CityPin(
          name: (result['display_name'] ?? query).toString(),
          point: LatLng(lat, lon),
        );
        if (!mounted) return;
        setState(() {
          _customPin = pin;
          _selected = pin;
          _showMapInfo = true;
        });
        _mapController.move(pin.point, 15);
        await _refreshAnalysis(pin);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('addressNotFound')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final analysis = widget.controller.analysis;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final point = _analysisPoint(analysis);
    final markers = <Marker>[..._cityMarkers(scheme)];
    if (_customPin != null)
      markers.add(_pinMarker(_customPin!, Colors.red, 46));
    if (point != null && _customPin == null) {
      markers.add(
        _pinMarker(
          _CityPin(name: (analysis?['address'] ?? '').toString(), point: point),
          const Color(0xFF8E44FF),
          52,
        ),
      );
    }
    markers.addAll(_parkingMarkers(scheme));
    markers.addAll(_liveCompetitorMarkers(scheme));
    markers.addAll(_locationMagnetMarkers(scheme));

    return SafeArea(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kazakhstanCenter,
              initialZoom: 4.6,
              minZoom: 3,
              maxZoom: 19,
              onMapReady: _moveToPendingAnalysis,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: ApiConfig.twoGisKey.isEmpty
                    ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                    : 'https://tile1.maps.2gis.com/tiles?key=${ApiConfig.twoGisKey}&ts=online_hd&v=1&layer=map&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.aibusinessagent.app',
                maxZoom: 19,
              ),
              CircleLayer(
                circles: _cities
                    .map(
                      (city) => CircleMarker(
                        point: city.point,
                        radius: 500,
                        useRadiusInMeter: true,
                        color: AppColors.secondary.withValues(alpha: .10),
                        borderColor: AppColors.secondary.withValues(alpha: .55),
                        borderStrokeWidth: 1.5,
                      ),
                    )
                    .toList(),
              ),
              PolygonLayer(polygons: _competitorPolygons(scheme)),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(25),
                  color: dark ? const Color(0xFF18181B) : Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    onSubmitted: (_) => _searchAddress(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: loc.t('searchAddressHint'),
                      suffixIcon: IconButton(
                        tooltip: loc.t('search'),
                        onPressed: _isSearching ? null : _searchAddress,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 112,
            child: Column(
              children: [
                _MapZoomButton(
                  icon: _locatingDevice ? Icons.gps_fixed : Icons.my_location,
                  onTap: () => _locateDevice(clearAnalysis: true),
                ),
                const SizedBox(height: 8),
                _MapZoomButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapZoomButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
              ],
            ),
          ),
          if (_showMapInfo)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: .22,
                minChildSize: .08,
                maxChildSize: .78,
                snap: true,
                snapSizes: const [.22, .78],
                builder: (context, scrollController) => Material(
                  elevation: 8,
                  color: dark
                      ? const Color(0xF218181B)
                      : const Color(0xF2FFFFFF),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outline.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _visibleCities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final city = _visibleCities[index];
                            final selected = _selected?.name == city.name;
                            return ChoiceChip(
                              label: Text(city.name),
                              selected: selected,
                              onSelected: (_) => _focusCity(city),
                              selectedColor: scheme.primary,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selected != null || analysis != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selected?.name ?? loc.t('mapTitle'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selected != null) ...[
                              IconButton(
                                tooltip: loc.t('locationPassport'),
                                onPressed: () =>
                                    ReportService().printLocationPassport(
                                      address: _selected!.name,
                                      score: 7.8,
                                      verdict:
                                          'Məkan ilkin mərhələ üçün uyğundur.',
                                      risks: const [
                                        'Rəqib sıxlığı yenidən yoxlanmalıdır',
                                      ],
                                    ),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                              ),
                              IconButton(
                                tooltip: loc.t('whatsappNegotiation'),
                                onPressed: () => _openWhatsApp(_selected!.name),
                                icon: const Icon(Icons.chat_outlined),
                              ),
                              IconButton(
                                tooltip: loc.t('openInMaps'),
                                onPressed: () =>
                                    _openInExternalMaps(_selected!.point),
                                icon: const Icon(Icons.navigation),
                              ),
                            ],
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MapInfoChip(
                              Icons.analytics_outlined,
                              '${loc.t('locationIndex')}: ${analysis?['score'] ?? '--'}/100',
                              scheme.primary,
                            ),
                            _MapInfoChip(
                              Icons.directions_walk,
                              '${loc.t('footTraffic')}: ${analysis?['pedestrian_traffic'] ?? (analysis?['pedestrian_traffic_estimate'] == null ? '--' : '~${analysis?['pedestrian_traffic_estimate']}')}',
                              AppColors.secondary,
                            ),
                            _MapInfoChip(
                              Icons.storefront_outlined,
                              '${loc.t('competitors')}: ${analysis?['competitors_500m'] ?? '--'}',
                              const Color(0xFFF59E0B),
                            ),
                            _MapInfoChip(
                              Icons.local_parking_outlined,
                              '${loc.t('parking')}: ${analysis?['parking_1km'] ?? '--'}',
                              const Color(0xFF38BDF8),
                            ),
                            _MapInfoChip(
                              Icons.directions_bus_outlined,
                              '${loc.t('stops')}: ${analysis?['transport_stops_1km'] ?? '--'}',
                              const Color(0xFF22C55E),
                            ),
                          ],
                        ),
                        _MapAnalysisDetails(analysis: analysis, scheme: scheme),
                        _MapCompetitorList(
                          competitors: analysis?['competitors'],
                          loc: loc,
                          scheme: scheme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _cityMarkers(ColorScheme scheme) => _cities.map((city) {
    final selected = _selected?.name == city.name;
    return Marker(
      point: city.point,
      width: selected ? 56 : 40,
      height: selected ? 56 : 40,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _focusCity(city),
        child: Icon(
          Icons.location_on,
          color: selected ? AppColors.secondary : scheme.primary,
          size: selected ? 42 : 34,
        ),
      ),
    );
  }).toList();

  Marker _pinMarker(_CityPin pin, Color color, double size) => Marker(
    point: pin.point,
    width: size + 18,
    height: size + 18,
    alignment: Alignment.topCenter,
    child: Icon(Icons.location_on, color: color, size: size),
  );

  List<Marker> _parkingMarkers(ColorScheme scheme) {
    final raw = widget.controller.analysis?['parking'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          final point = item['point'] ?? item['coordinates'];
          double? lat;
          double? lon;
          if (point is Map) {
            lat = double.tryParse(point['lat']?.toString() ?? '');
            lon = double.tryParse(point['lon']?.toString() ?? '');
          } else if (point is List && point.length >= 2) {
            lat = double.tryParse(point[0].toString());
            lon = double.tryParse(point[1].toString());
          }
          if (lat == null || lon == null) return null;
          final name = item['name'] ?? item['title'] ?? 'Parking';
          final distance = item['distance_meters'] ?? item['distance'] ?? '—';
          return Marker(
            point: LatLng(lat, lon),
            width: 36,
            height: 36,
            child: Tooltip(
              message: '$name • ${_formatDistance(distance)}',
              child: Icon(
                Icons.local_parking,
                color: scheme.tertiary,
                size: 25,
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();
  }

  List<Marker> _locationMagnetMarkers(ColorScheme scheme) {
    final analysis = widget.controller.analysis;
    final items = <Map>[
      if (analysis?['transport_stops'] is List)
        ...(analysis!['transport_stops'] as List).whereType<Map>(),
      if (analysis?['nearby_places'] is List)
        ...(analysis!['nearby_places'] as List).whereType<Map>(),
    ];
    return items
        .map((item) {
          final point = item['point'];
          if (point is! Map) return null;
          final lat = double.tryParse(point['lat']?.toString() ?? '');
          final lon = double.tryParse(point['lon']?.toString() ?? '');
          if (lat == null || lon == null) return null;
          final isTransport = item['kind'] == 'transport';
          return Marker(
            point: LatLng(lat, lon),
            width: 38,
            height: 38,
            child: Tooltip(
              message: item['name']?.toString() ?? 'Yaxın obyekt',
              child: Icon(
                isTransport ? Icons.directions_bus : Icons.place,
                color: isTransport ? scheme.tertiary : const Color(0xFF0EA5E9),
                size: 25,
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();
  }

  String _formatDistance(dynamic value) {
    final meters = num.tryParse(value?.toString() ?? '');
    if (meters == null) return '—';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  void _openInExternalMaps(LatLng point) {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  List<Polygon> _competitorPolygons(ColorScheme scheme) {
    final raw = widget.controller.analysis?['competitors'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          final point = item['point'];
          final lat = double.tryParse(point?['lat']?.toString() ?? '');
          final lon = double.tryParse(point?['lon']?.toString() ?? '');
          if (lat == null || lon == null) return null;
          // A clear blue square around the real 2GIS point. The box is only a
          // visual highlight; the competitor coordinates remain the live point.
          const delta = 0.00035;
          const competitorBlue = Color(0xFF2563EB);
          return Polygon(
            points: [
              LatLng(lat - delta, lon - delta),
              LatLng(lat - delta, lon + delta),
              LatLng(lat + delta, lon + delta),
              LatLng(lat + delta, lon - delta),
            ],
            color: competitorBlue.withValues(alpha: 0.28),
            borderColor: competitorBlue,
            borderStrokeWidth: 3,
          );
        })
        .whereType<Polygon>()
        .toList();
  }

  List<Marker> _liveCompetitorMarkers(ColorScheme scheme) {
    final raw = widget.controller.analysis?['competitors'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          final point = item['point'];
          final lat = double.tryParse(point?['lat']?.toString() ?? '');
          final lon = double.tryParse(point?['lon']?.toString() ?? '');
          if (lat == null || lon == null) return null;
          return Marker(
            point: LatLng(lat, lon),
            width: 42,
            height: 42,
            alignment: Alignment.topCenter,
            child: Tooltip(
              message:
                  '${item['name'] ?? 'Rəqib'} • ${item['distance_meters'] ?? '—'} m',
              child: Icon(Icons.storefront, color: scheme.error, size: 28),
            ),
          );
        })
        .whereType<Marker>()
        .toList();
  }
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 18)),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapAnalysisDetails extends StatelessWidget {
  const _MapAnalysisDetails({required this.analysis, required this.scheme});

  final Map<String, dynamic>? analysis;
  final ColorScheme scheme;

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    if (value is List) return value.join(', ');
    if (value is Map)
      return value.values.where((item) => item != null).join(', ');
    return value.toString();
  }

  String _distance(dynamic value) {
    final meters = num.tryParse(value?.toString() ?? '');
    if (meters == null) return '—';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  Widget _section(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _line(String label, dynamic value) {
    final text = _value(value);
    if (text == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 142,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: scheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _places(dynamic raw, {required String emptyLabel}) {
    if (raw is! List || raw.isEmpty) {
      return [_line(emptyLabel, '—')];
    }
    return raw.take(10).whereType<Map>().map((item) {
      final name = item['name'] ?? item['title'] ?? emptyLabel;
      final distance = _distance(item['distance_meters'] ?? item['distance']);
      final address = item['address'];
      return _line(
        name.toString(),
        [
          distance,
          if (address != null && address.toString().isNotEmpty) address,
        ].join(' • '),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = analysis;
    if (data == null) return const SizedBox.shrink();
    final quality = data['analysis_quality'] is Map
        ? data['analysis_quality'] as Map
        : const <dynamic, dynamic>{};
    final insights = data['insights'] is Map
        ? data['insights'] as Map
        : const <dynamic, dynamic>{};
    final noise = insights['digital_noise'] is Map
        ? insights['digital_noise'] as Map
        : const <dynamic, dynamic>{};
    final peak = insights['peak_comparison'] is Map
        ? insights['peak_comparison'] as Map
        : const <dynamic, dynamic>{};
    final magnets = insights['location_magnets'] is Map
        ? insights['location_magnets'] as Map
        : const <dynamic, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Məkan və analiz', [
          _line('Mənbə', data['source']),
          _line('Ünvan', data['address']),
          _line('Yenilənib', data['updated_at']),
          _line('Biznes sorğusu', data['business_query']),
          _line('Ümumi bal', data['score']),
          _line('Əlçatanlıq balı', data['accessibility_score']),
          _line('Rəqabət balı', data['competition_score']),
          _line('Ən yaxın rəqib', _distance(data['nearest_competitor_meters'])),
          _line('500 m rəqib sayı', data['competitors_500m']),
          _line('1 km rəqib sayı', data['competitors_1km']),
          _line('1 km yaxın obyekt', data['nearby_places_1km']),
        ]),
        _section('Məlumat keyfiyyəti', [
          _line('Geokodlaşdırılmış nöqtə', quality['geocoded_point']),
          _line('Canlı rəqib sayı', quality['competitor_count_is_live']),
          _line('Detallar yüklənib', quality['competitor_details_loaded']),
          _line(
            'Piyada saatlıq data',
            quality['pedestrian_hourly_data_available'],
          ),
          _line('Qeyd', quality['note']),
        ]),
        _section('Trafik və rəqəmsal göstəricilər', [
          _line('Piyada trafiki', data['pedestrian_traffic']),
          _line('Trafik təxmini', data['pedestrian_traffic_estimate']),
          _line('Trafik mənbəyi', data['pedestrian_traffic_source']),
          _line('Trafik qeydi', data['pedestrian_traffic_note']),
          _line('Ümumi rəy sayı', noise['review_total']),
          _line(
            'Cədvəli olan rəqiblər',
            '${peak['schedule_available_for'] ?? '—'}/${peak['competitors_sample'] ?? '—'}',
          ),
          _line('Pik müqayisə mənbəyi', peak['source']),
        ]),
        _section('Məkan maqnitləri', [
          _line(
            'Ən yaxın dayanacaq',
            _distance(magnets['nearest_transport_meters']),
          ),
          _line('Ən yaxın obyekt', magnets['nearest_place_name']),
          _line('Obyektə məsafə', _distance(magnets['nearest_place_meters'])),
          _line(
            'Rəqibə məsafə',
            _distance(magnets['competitor_distance_meters']),
          ),
        ]),
        _section(
          'Nəqliyyat dayanacaqları',
          _places(
            data['transport_stops'],
            emptyLabel: 'Dayanacaq məlumatı yoxdur',
          ),
        ),
        _section(
          'Parking',
          _places(data['parking'], emptyLabel: 'Parking məlumatı yoxdur'),
        ),
        _section(
          'Yaxın obyektlər',
          _places(
            data['nearby_places'],
            emptyLabel: 'Yaxın obyekt məlumatı yoxdur',
          ),
        ),
      ],
    );
  }
}

class _MapCompetitorList extends StatelessWidget {
  const _MapCompetitorList({
    required this.competitors,
    required this.loc,
    required this.scheme,
  });

  final dynamic competitors;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final items = <Map>[];
    if (competitors is List) {
      for (final item in competitors) {
        if (item is Map &&
            ((item['name']?.toString().trim().isNotEmpty ?? false) ||
                (item['address']?.toString().trim().isNotEmpty ?? false))) {
          items.add(item);
        }
      }
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${loc.t('competitors')}: 0',
          style: TextStyle(
            color: scheme.outline,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc.t('competitorList')} · ${items.length}',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 270),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, index) => _MapCompetitorRow(
                item: items[index],
                loc: loc,
                scheme: scheme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCompetitorRow extends StatelessWidget {
  const _MapCompetitorRow({
    required this.item,
    required this.loc,
    required this.scheme,
  });

  final Map item;
  final AppLocalizations loc;
  final ColorScheme scheme;

  String _distance(dynamic value) {
    if (value == null) return '—';
    final meters = num.tryParse(value.toString());
    if (meters == null) return '—';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  String _number(dynamic value) {
    if (value == null) return '—';
    final number = num.tryParse(value.toString());
    return number == null ? '—' : number.toString();
  }

  String _category() {
    final rubrics = item['rubrics'];
    if (rubrics is List && rubrics.isNotEmpty) {
      return rubrics.first.toString();
    }
    return item['category']?.toString() ?? '2GIS';
  }

  String _subtitle() {
    final category = _category();
    final address = item['address']?.toString().trim() ?? '';
    return address.isEmpty ? category : '$category · $address';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = item['name']?.toString().trim().isNotEmpty == true
        ? item['name'].toString()
        : '2GIS';
    final rating = item['rating'] ?? item['rating_avg'];
    final reviewCount = item['review_count'] ?? item['reviews_count'];
    final schedule =
        item['schedule_available'] == true ||
        item['schedule'] != null ||
        item['has_schedule'] == true;
    final distance = item['distance_meters'] ?? item['distance'];
    final parking = item['nearest_parking_meters'] ?? item['parking_distance'];
    final transport =
        item['nearest_transport_meters'] ?? item['transport_distance'];
    final background = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222228)
        : const Color(0xFFF4F4F7);

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 16, color: scheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (rating != null) ...[
                const Icon(Icons.star, size: 13, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  _number(rating),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _subtitle(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: scheme.outline),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MapCompetitorMeta(
                icon: Icons.near_me_outlined,
                text: '${loc.t('distance')}: ${_distance(distance)}',
                color: scheme.primary,
              ),
              _MapCompetitorMeta(
                icon: Icons.local_parking_outlined,
                text:
                    '${loc.t('parking')}: ${_distance(parking)}'
                    '${item['parking_within_500m'] == null ? '' : ' (${item['parking_within_500m']})'}',
                color: const Color(0xFF38BDF8),
              ),
              _MapCompetitorMeta(
                icon: Icons.directions_bus_outlined,
                text:
                    '${loc.t('stops')}: ${_distance(transport)}'
                    '${item['transport_stops_within_500m'] == null ? '' : ' (${item['transport_stops_within_500m']})'}',
                color: const Color(0xFF22C55E),
              ),
              _MapCompetitorMeta(
                icon: Icons.reviews_outlined,
                text: '${loc.t('reviews')}: ${_number(reviewCount)}',
                color: Colors.amber,
              ),
              _MapCompetitorMeta(
                icon: Icons.directions_walk_outlined,
                text: '${loc.t('traffic')}: ${loc.t('trafficUnavailable')}',
                color: scheme.outline,
              ),
              if (schedule)
                _MapCompetitorMeta(
                  icon: Icons.schedule_outlined,
                  text: loc.t('hoursAvailable'),
                  color: scheme.secondary,
                ),
            ],
          ),
          if (item['phone'] != null ||
              item['website'] != null ||
              item['business_status'] != null ||
              item['price_level'] != null ||
              item['editorial_summary'] != null ||
              item['description'] != null ||
              item['schedule_special'] != null ||
              item['links'] != null ||
              item['contact_groups'] != null ||
              item['flags'] != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (item['phone'] != null) 'Tel: ${item['phone']}',
                if (item['price_level'] != null)
                  'Qiymət səviyyəsi: ${item['price_level']}',
                if (item['business_status'] != null)
                  'Status: ${item['business_status']}',
                if (item['website'] != null) 'Sayt: ${item['website']}',
                if (item['editorial_summary'] != null)
                  item['editorial_summary'].toString(),
                if (item['description'] != null) item['description'].toString(),
                if (item['schedule_special'] != null)
                  'Xüsusi qrafik: ${item['schedule_special']}',
                if (item['links'] != null) 'Linklər: ${item['links']}',
                if (item['contact_groups'] != null)
                  'Əlaqə: ${item['contact_groups']}',
                if (item['flags'] is List && (item['flags'] as List).isNotEmpty)
                  'Status detalları: ${(item['flags'] as List).join(', ')}',
              ].join(' • '),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapCompetitorMeta extends StatelessWidget {
  const _MapCompetitorMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ============================================================
// CHAT
// ============================================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.controller});

  final LocationAnalysisController controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(author: 'assistant', text: ''),
  ];
  bool _isSending = false;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.length == 1) {
      _messages[0] = _ChatMessage(
        author: 'assistant',
        text: AppLocalizations.of(context).t('assistantWelcome'),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(author: 'user', text: prompt));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await widget.controller.analyzeFromPrompt(prompt);
      final liveAnalysis = widget.controller.contextForAi;
      if (liveAnalysis != null && mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              author: 'assistant',
              text: _formatLiveAnalysis(liveAnalysis),
            ),
          );
        });
      }
      final answer = await _aiService.generateResponse(
        prompt,
        language: AppLocalizations.of(context).locale.languageCode,
        locationContext: widget.controller.contextForAi,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(author: 'assistant', text: answer));
        _isSending = false;
      });
      await _tts.setLanguage('az-AZ');
      await _tts.speak(answer);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            author: 'assistant',
            text: AppLocalizations.of(context).t('aiBackendError'),
          ),
        );
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  String _formatLiveAnalysis(Map<String, dynamic> analysis) {
    final loc = AppLocalizations.of(context);
    final score = analysis['score']?.toString() ?? '—';
    final traffic = analysis['pedestrian_traffic']?.toString() ?? '—';
    final competitors = analysis['competitors_500m']?.toString() ?? '—';
    final nearest = analysis['nearest_competitor_meters']?.toString() ?? '—';
    return '${loc.t('liveReportTitle')}\n'
        '• ${loc.t('liveLocationIndex')}: $score/100\n'
        '• ${loc.t('liveTrafficIndex')}: $traffic/100\n'
        '• ${loc.t('liveCompetitors')}: $competitors\n'
        '• ${loc.t('liveNearest')}: $nearest m\n\n'
        '${loc.t('liveMapHint')}';
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _controller.text = result.recognizedWords);
      },
    );
  }

  void _sendPreset(String value) {
    _controller.text = value;
    _sendMessage();
  }

  Widget _botBubble(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text, style: const TextStyle(height: 1.3)),
    );
  }

  Widget _optionButton(String text, {required IconData icon}) {
    return OutlinedButton.icon(
      onPressed: _isSending ? null : () => _sendPreset(text),
      icon: Icon(icon, size: 18),
      label: Align(alignment: Alignment.centerLeft, child: Text(text)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFA855F7),
        side: BorderSide(color: const Color(0xFFA855F7).withValues(alpha: .55)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _categoryButton(String text) {
    return Expanded(
      child: OutlinedButton(
        onPressed: _isSending ? null : () => _sendPreset(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  child: Icon(Icons.smart_toy_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('assistantTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        loc.t('assistantSubtitle'),
                        style: TextStyle(color: scheme.outline, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.lg),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                ..._messages.map((message) {
                  final isUser = message.author == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFFA855F7)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: isUser
                            ? null
                            : Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : null,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                }),
                if (_messages.length == 1) ...[
                  const SizedBox(height: 4),
                  _optionButton(
                    loc.t('assistantStartNew'),
                    icon: Icons.compass_calibration,
                  ),
                  const SizedBox(height: 8),
                  _optionButton(
                    loc.t('assistantOwnAddress'),
                    icon: Icons.push_pin_outlined,
                  ),
                  const SizedBox(height: 16),
                  _botBubble(loc.t('assistantBusinessQuestion')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _categoryButton(loc.t('assistantFood')),
                      const SizedBox(width: 8),
                      _categoryButton(loc.t('assistantRetail')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _categoryButton(loc.t('assistantBeauty')),
                      const SizedBox(width: 8),
                      _categoryButton(loc.t('assistantOther')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('...', style: TextStyle(color: scheme.outline)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              8,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: loc.t('assistantHint'),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E22)
                          : Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: _isListening
                      ? loc.t('stopListening')
                      : loc.t('voiceInput'),
                  onPressed: _toggleListening,
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic_none_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(
                    0xFFA855F7,
                  ).withValues(alpha: .65),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.author, required this.text});

  final String author;
  final String text;
}

// ============================================================
// PROFILE
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLocaleChanged,
    required this.currentLocaleCode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.audits,
    required this.onAuditSelected,
    required this.onAuditDeleted,
    required this.mapProvider,
    required this.onMapProviderChanged,
  });

  final Map<String, dynamic>? user;
  final ValueChanged<Locale> onLocaleChanged;
  final String currentLocaleCode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;
  final List<Map<String, dynamic>> audits;
  final ValueChanged<Map<String, dynamic>> onAuditSelected;
  final ValueChanged<Map<String, dynamic>> onAuditDeleted;
  final String mapProvider;
  final ValueChanged<String> onMapProviderChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _newCompetitorsNotify = true;
  Uint8List? _photoBytes;

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _photoBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final name = (widget.user?['name'] as String?)?.trim();
    final photoUrl = (widget.user?['photoUrl'] as String?)?.trim();
    final displayName = name == null || name.isEmpty
        ? loc.t('entrepreneur')
        : name;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1E28);
    final mutedColor = isDark ? Colors.grey : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E22) : Colors.white;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(32),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFA855F7),
                        backgroundImage: _photoBytes != null
                            ? MemoryImage(_photoBytes!)
                            : photoUrl == null || photoUrl.isEmpty
                            ? null
                            : NetworkImage(photoUrl),
                        child:
                            _photoBytes == null &&
                                (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                displayName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.t('planPro'),
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(loc.t('savedAudits'), mutedColor),
          const SizedBox(height: 10),
          if (widget.audits.isEmpty)
            Text(loc.t('noAudits'), style: TextStyle(color: mutedColor))
          else
            SizedBox(
              height: widget.audits.length > 5 ? 360 : null,
              child: ListView.builder(
                shrinkWrap: widget.audits.length <= 5,
                itemCount: widget.audits.length,
                itemBuilder: (context, index) {
                  final audit = widget.audits[index];
                  final saved = audit['analysis'] is Map
                      ? Map<String, dynamic>.from(audit['analysis'] as Map)
                      : <String, dynamic>{};
                  final auditAddress =
                      (audit['displayAddress'] ??
                              audit['address'] ??
                              saved['address'] ??
                              loc.t('mapTitle'))
                          .toString();
                  final date =
                      (audit['displayDate'] ?? audit['createdAt'] ?? '')
                          .toString();
                  final status = (audit['status'] ?? loc.t('auditStatus'))
                      .toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildAuditCard(
                      auditAddress,
                      date,
                      surfaceColor,
                      textColor,
                      mutedColor,
                      status,
                      onTap: () => widget.onAuditSelected(audit),
                      onDelete: () => _confirmAuditDelete(context, audit),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          _sectionTitle(loc.t('settingsTitle'), mutedColor),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.mapProvider,
            decoration: InputDecoration(
              labelText: 'Xəritə və analiz mənbəyi',
              labelStyle: TextStyle(color: mutedColor, fontSize: 12),
            ),
            items: const [
              DropdownMenuItem(value: '2gis', child: Text('2GIS')),
              DropdownMenuItem(value: 'google', child: Text('Google')),
            ],
            onChanged: (value) {
              if (value != null) widget.onMapProviderChanged(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.translate, size: 16, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              Text(
                loc.t('language'),
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLangChip('Русский', 'ru', widget.currentLocaleCode == 'ru'),
              const SizedBox(width: 8),
              _buildLangChip('Қазақша', 'kk', widget.currentLocaleCode == 'kk'),
              const SizedBox(width: 8),
              _buildLangChip('English', 'en', widget.currentLocaleCode == 'en'),
              const SizedBox(width: 8),
              _buildLangChip(
                'Azərbaycan',
                'az',
                widget.currentLocaleCode == 'az',
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(loc.t('logout')),
                  content: Text(loc.t('logoutConfirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(loc.t('cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(loc.t('logout')),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) await widget.onLogout();
            },
            icon: const Icon(Icons.logout),
            label: Text(loc.t('logout')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 18,
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('newCompetitors'),
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                      Text(
                        loc.t('notifyCompetitors'),
                        style: TextStyle(color: mutedColor, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _newCompetitorsNotify,
                activeColor: const Color(0xFFA855F7),
                onChanged: (value) =>
                    setState(() => _newCompetitorsNotify = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Text(
    title,
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );

  Future<void> _confirmAuditDelete(
    BuildContext context,
    Map<String, dynamic> audit,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.t('deleteAudit')),
        content: Text(loc.t('deleteAuditConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.t('deleteAudit')),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onAuditDeleted(audit);
  }

  Widget _buildAuditCard(
    String title,
    String subtitle,
    Color surface,
    Color text,
    Color muted,
    String status, {
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.purpleAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: muted, fontSize: 9)),
                ],
              ),
            ),
            _buildStatusBadge(status, muted),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Auditi sil',
              color: muted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color muted) {
    final normalized = status.toLowerCase();
    final isReady =
        normalized.contains('hazır') ||
        normalized.contains('ready') ||
        normalized.contains('готов');
    final statusColor = isReady
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.hourglass_empty,
            color: statusColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: statusColor, fontSize: 10)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 10),
        ],
      ),
    );
  }

  Widget _buildLangChip(String language, String code, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onLocaleChanged(Locale(code));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFA855F7) : const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            language,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

String _languageName(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'ru':
      return 'Русский';
    case 'kk':
      return 'Қазақша';
    default:
      return 'Azərbaycan';
  }
}

void _showLanguagePicker(
  BuildContext context,
  ValueChanged<Locale> onChanged,
  String currentCode,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Azərbaycan'),
            trailing: currentCode == 'az' ? const Icon(Icons.check) : null,
            onTap: () {
              onChanged(const Locale('az'));
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('English'),
            trailing: currentCode == 'en' ? const Icon(Icons.check) : null,
            onTap: () {
              onChanged(const Locale('en'));
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Русский'),
            trailing: currentCode == 'ru' ? const Icon(Icons.check) : null,
            onTap: () {
              onChanged(const Locale('ru'));
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Қазақша'),
            trailing: currentCode == 'kk' ? const Icon(Icons.check) : null,
            onTap: () {
              onChanged(const Locale('kk'));
              Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    ),
  );
}

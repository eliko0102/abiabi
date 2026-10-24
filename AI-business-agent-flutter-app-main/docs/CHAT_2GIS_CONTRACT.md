# Xəritə axtarışı və 2GIS → Çat müqaviləsi

Bu sənəd üç problemi birlikdə həll edən axını təsvir edir:

1. Xəritədə **ölkə / şəhər / ünvan** axtarışı işləmirdi.
2. Yeni nöqtə və köhnə nöqtə formalarında **ünvan yazarkən təkliflər** gəlmirdi.
3. 2GIS analizini **çata ötürüb** həmin analiz üzərində danışmaq mümkün deyildi.

---

## 1. Nə üçün əvvəl işləmirdi

### Xəritə axtarışı

`MapScreen` axtarışı birbaşa **məkan analizi** endpoint-inə göndərirdi:

```
axtarış mətni → POST /api/location-analysis → 2GIS → marker
```

Bu yanaşmanın üç nəticəsi var idi:

- Ölkə adı (`Qazaxıstan`, `Almatı`) üçün 2GIS-də **biznes/ünvan** nəticəsi yoxdur, ona görə heç nə tapılmırdı.
- `TWOGIS_API_KEY` yoxdursa və ya Render servisi soyuq başlayıbsa, axtarış tamamilə boş qayıdırdı.
- `widget.city` (məs. `Aktau`) axtarışa məcburi əlavə olunurdu, yəni `Qazaxıstan` yazanda `Aktau, Qazaxıstan` axtarılır və nəticə Aktau olurdu.

### Ünvan təklifləri

`AddressAutocompleteField` yalnız `/api/suggest`-ə güvənirdi. Sorğu xəta verdikdə (timeout, soyuq server) nəticə **səssizcə boş** olurdu; istifadəçi “nəticə tapılmadı” ilə səhv (server xətası) arasındakı fərqi görmürdü. Backup Nominatim sorğusunda `Accept-Language` yox idi, ona görə `Almatı`, `Баку` kimi yerli yazılışlar tapılmırdı. Seçilmiş məkanın koordinatı atılırdı və audit mətni **yenidən geokodlaşdırırdı** — bəzən başqa şəhərdə.

### Çat

- `ChatScreen` hər mesajda `analyzeFromPrompt()` çağırırdı. Bu funksiya əvvəlcə `analysis = null` edirdi; axtarış uğursuz olsa, **əldə olan 2GIS hesabatı silinirdi** və AI boş kontekst alırdı.
- Hesabat ekranındakı “Hesabat barədə AI-dan soruş” düyməsi sadəcə boş bottom sheet açırdı — heç bir ötürmə yox idi.
- `/api/chat` bütün analiz obyektini JSON kimi prompt-a yığırdı; cavabın strukturu və davam sualları yox idi.

---

## 2. Axtarış axını (yeni)

```
İstifadəçi yazır
   │
   ▼
AddressAutocompleteField  (320 ms debounce, min 2 simvol)
   │  GET /api/suggest?q=...&city=...&lang=az
   ▼
places.js  searchPlaces()
   ├─ 1. Gazetteer: ölkə/şəhər adları az/en/ru/kk + yerli yazılışlar
   │      Qazaxıstan → country + Astana, Almaty, Aktau...
   ├─ 2. 2GIS Catalog API (açar varsa): ünvan və bizneslər
      └─ 3. Nominatim (açar yoxdursa və ya nəticə azdırsa):
         Qazaxıstan üçün countrycodes=kz, accept-language=kk,ru,en
   ▼
Normallaşdırılmış nəticə:
{ id, name, subtitle, type: country|city|address|poi,
  lat, lon, point, bbox, city, country_code, zoom, source }
   ▼
UI: tip ikonu + şəhər/region alt yazısı
   ▼
Seçim → onSelected(place)
   ├─ country/city → xəritə bbox-a görə zoom (analiz sorğusu YOXDUR)
   └─ address/poi  → marker + “Bu məkanı analiz et” düyməsi
```

Backend əlçatmazdırsa `PlaceSearchService` **birbaşa Nominatim-ə** düşür. Bu, soyuq Render instansiyasında da ünvan təkliflərinin görünməsini təmin edir.

### Biznes adları (məs. “Olzha fitness club”)

Nominatim biznes kataloqu deyil, ona görə biznes adları üçün əlavə iki pillə var:

1. **2GIS Catalog API** — düzgün `TWOGIS_API_KEY` ilə biznes kartı, reytinq, qrafik və rəylər gəlir. Bu, əsas mənbədir.
2. **Latin → kiril variantları** — Qazaxıstanda obyektlər çox vaxt rus/qazax kirilində qeydiyyatdadır: `Olzhay` və `Olzhai` yazılışları `олжай` və `олжа` variantları ilə, `Olzha` isə `олжа` ilə axtarılır. Kateqoriya sözləri çıxarılan brend variantı da yoxlanılır.
3. **Qismən nəticələri tamamla** — Aktau şəhəri məlumdursa, backend Nominatim üçün `countrycodes=kz` göndərir və qismən uyğunluq tapılsa belə kiril variantlarını 2GIS-də yoxlayır. `/3.0/suggests` və `/3.0/items` nəticələri birləşdirilir ki, bir endpoint-in qismən nəticəsi digər endpoint-dəki biznesi gizlətməsin.

Uyğun biznes 2GIS kataloqunda olduqda `Olzhay` + `city=Aktau` axtarışı **ОЛЖАЙ** kimi kiril qeydiyyatlı nəticəni təklif edə bilər. Bu fallback ad yazılışını genişləndirir; dəqiq biznes məlumatı üçün Render-də ayrıca Catalog API açarı olan `TWOGIS_API_KEY` lazımdır.

> Qeyd: `lib/config/api_config.dart`-dakı açarlı tile URL-i **Catalog API açarı deyil** — catalog sorğuları `403 incorrect key` qaytarır. Render-də `TWOGIS_API_KEY` ayrıca Catalog API açarı ilə verilməlidir.

### Nəticə növləri

| `type` | Mənası | Xəritədə davranış |
|---|---|---|
| `country` | Ölkə (məs. Qazaxıstan) | `bbox` ilə bütün ölkəyə zoom, pin yoxdur |
| `city` | Şəhər | `bbox` ilə şəhərə zoom |
| `address` | Küçə / bina | marker + analiz düyməsi |
| `poi` | Biznes / obyekt | marker + analiz düyməsi |

---

## 3. 2GIS → Çat ötürmə məntiqi

### Vəziyyət maşını

```
[Xəritə] və ya [Audit hesabatı]
        │  istifadəçi “2GIS analizini çata göndər” basır
        ▼
LocationAnalysisController.sendAnalysisToChat()
        │  chatHandoff.value = ChatHandoff(id, analysis snapshot)
        ▼
HomeShell: _selectedIndex = 2 (Çat tabı)
        ▼
ChatScreen._onHandoff()
        ├─ snapshot-ı _analysisContext kimi saxlayır
        ├─ “2GIS analizi əlavə edildi” kartını göstərir
        └─ avtomatik sual göndərir: loc.t('analysisPrompt')
        ▼
POST /api/chat { prompt, language, analysis_context, conversation }
        ▼
Cavab: message + follow_ups[]
        ▼
Bubble + “Növbəti suallar” chip-ləri
```

Əsas qaydalar:

- Çat **ünvanı yenidən axtarmır**. Ötürülən snapshot həmin hesabatın dəqiq nəticəsidir.
- Snapshot `ValueNotifier` ilə ötürülür və `ChatScreen` onu dərhal `null` edir — tab dəyişəndə eyni hesabat təkrar göndərilmir.
- Sonrakı bütün suallar `_analysisContext` ilə gedir; istifadəçi yeni hesabat göndərənə qədər kontekst dəyişmir.
- Uğursuz axtarış artıq mövcud hesabatı silmir (`analyze()` əvvəlki analizi bərpa edir).

### API müqaviləsi

**Sorğu — `POST /api/chat`**

```json
{
  "prompt": "Rəqibləri necə üstələyə bilərəm?",
  "language": "az",
  "conversation": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ],
  "analysis_context": {
    "address": "Aktau, 14 mkr",
    "point": { "lat": 43.6353, "lon": 51.1682 },
    "score": 72,
    "competitors_500m": 6,
    "competitors": [{ "name": "Cafe A", "distance_meters": 120 }],
    "parking_1km": 0,
    "transport_stops_1km": 4,
    "insights": { }
  }
}
```

`analysis_context` (köhnə `location_context` da qəbul olunur) **kompaktlaşdırılır**: rəqiblər 6, dayanacaq/parkinq 6, siyahıların hər biri yalnız çat üçün lazım olan sahələr. Bu, prompt-u kiçik və ucuz saxlayır.

**Cavab — 200**

```json
{
  "success": true,
  "message": "**Məkanın qiymətləndirilməsi** ...",
  "analysis_used": true,
  "analysis_address": "Aktau, 14 mkr",
  "follow_ups": [
    "Rəqabət yüksəkdir — necə fərqlənməliyəm?",
    "Yaxınlıqda parkinq yoxdur — nə etməliyəm?",
    "2GIS-də görünürlüyü necə artırım?"
  ]
}
```

### Cavabın formatı (modelə verilən qayda)

Analiz varsa cavab mütləq üç başlıqda olur:

1. **Məkanın qiymətləndirilməsi** — ünvan, bal, əlçatanlıq, rəqabət.
2. **İnsan axınını artırmaq üçün 3 addım** — hər addım konkret və icra oluna bilən.
3. **Risklər və həlli** — parkinq, görünürlük, rəqabət.

Əlavə qaydalar:

- Yalnız verilən rəqəmlərdən istifadə; olmayan göstərici üçün “2GIS məlumatında yoxdur”.
- Rəqiblər ad və məsafə ilə göstərilir.
- Sonda bir cümləlik “növbəti addım”.

Analiz yoxdursa model ünvan istəyir; uydurma rəqəm vermir.

`follow_ups` modeldən asılı deyil — backend onları **deterministik** qurur (parkinq yoxdursa parkinq sualı, rəqabət ≥5 olarsa fərqlənmə sualı). Beləliklə UI-də həmişə işlək davam düymələri olur.

---

## 4. Yeni nöqtə / köhnə nöqtə formaları

- Hər iki formada `AddressAutocompleteField` eyni `/api/suggest` axınından istifadə edir.
- Seçilmiş məkan `_selectedPlace` kimi saxlanılır və audit sorğusuna **`point: {lat, lon}`** kimi ötürülür.
- Backend `point` alırsa geokodlaşdırmanı tamamilə atlayır və məhz həmin nöqtəni analiz edir.
- İstifadəçi siyahıdan seçmədən mətn yazıb göndərsə, köhnə davranış qalır: backend mətni geokodlaşdırır (2GIS → ümumi axtarış).
- Yeni nöqtə çatında analizdən sonra `_analysisContext` saxlanılır; sonrakı suallar həmin hesabatla cavablanır.

---

## 5. Xəta halları

| Hal | Davranış |
|---|---|
| Backend 500 / timeout | `PlaceSearchService` birbaşa Nominatim-ə keçir |
| Nominatim də əlçatmaz | UI “Axtarış serverinə qoşulmaq alınmadı” göstərir |
| Nəticə yoxdur | UI “Nəticə tapılmadı” göstərir (xəta ilə qarışdırılmır) |
| 2GIS açarı yoxdur | Axtarış işləyir (gazetteer + OSM); analiz `TWOGIS_API_KEY konfiqurasiya edilməyib` qaytarır |
| AI açarı yoxdur | `/api/chat` 500 + aydın mesaj; çat UI-da `aiBackendError` |
| Analiz yoxdur, çat açıqdır | AI ünvan istəyir; “2GIS analizini göndər” düyməsi xəritədə/hesabatda görünmür |

---

## 6. Testlər

```bash
cd backend
npm test
```

Testlər şəbəkəsiz işləyir:

- `normalize()` az/kk/ru yazılışlarını birləşdirir.
- `Qazaxıstan` → ölkə + şəhərlər, `bbox` ilə.
- `Almatı` → tək `Almaty` nəticəsi (dublikat yoxdur).
- Çat prompt-una analiz, dil və “rəqəm uydurma” qaydası düşür.
- `follow_ups` parkinq/rəqabət vəziyyətinə görə dəyişir.
- `/api/suggest` qısa sorğunu 400 ilə rədd edir.
- `/api/chat` promptsuz sorğunu 400, açarsız sorğunu 500 qaytarır.

Flutter tərəfi:

```bash
flutter analyze
```

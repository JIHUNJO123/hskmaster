# HSK Master - 설정 완료 체크리스트

## ✅ 완료된 작업

### 1. 로고 위치
- **위치**: `c:\Users\hooni\Desktop\hsk_vocab_app\assets\icon\app_icon.png`
- 첨부하신 로고를 위 경로에 `app_icon.png` 이름으로 저장해주세요

### 2. 앱 기본 정보
✅ 앱 제목: HSK Master
✅ 번들 ID: com.jihunjo.hskmaster
✅ SKU: hskmaster_ios_001
✅ 패키지명(Android): com.jihunjo.hskmaster

### 3. 파일 수정 완료
✅ `pubspec.yaml` - 앱 설명 및 이름 업데이트
✅ `android/app/build.gradle.kts` - 번들 ID 및 패키지명 변경
✅ `android/app/src/main/AndroidManifest.xml` - 앱 이름 및 AdMob App ID 변경
✅ `ios/Runner/Info.plist` - 앱 이름 및 AdMob App ID 변경
✅ `lib/services/ad_service.dart` - AdMob 광고 ID 변경
✅ `lib/services/purchase_service.dart` - IAP 제품 ID 변경

### 4. AdMob 설정
#### Android
- App ID: ca-app-pub-5837885590326347~8904178878
- 배너: ca-app-pub-5837885590326347/9421401234
- 전면: ca-app-pub-5837885590326347/5271414994

#### iOS
- App ID: ca-app-pub-5837885590326347~1276329661
- 배너: ca-app-pub-5837885590326347/9742617823
- 전면: ca-app-pub-5837885590326347/8325594378

### 5. IAP (인앱 구매)
✅ 제품 ID: com.hskmaster.app.removeads
✅ 가격: $1.99 USD

### 6. 웹사이트 (GitHub Pages 호스팅 준비됨)
✅ 개인정보처리방침: `docs/privacy.html`
✅ 고객 지원: `docs/support.html`
✅ 마케팅 페이지: `docs/index.html`

**호스팅 후 URL:**
- 개인정보처리방침: https://jihunjo123.github.io/hskmaster/privacy.html
- 마케팅 URL: https://jihunjo123.github.io/hskmaster/
- 지원 URL: https://jihunjo123.github.io/hskmaster/support.html

### 7. 앱 스토어 메타데이터
✅ `APP_STORE_METADATA.md` 파일에 모든 정보 정리됨
- 앱 프로모션 텍스트
- 앱 자세한 설명 (한국어/영어)
- 키워드
- 앱 부제

### 8. 스크롤 위치 저장 기능
✅ 단어 리스트 스크롤 위치 저장/복원 (이미 구현됨)
✅ 플래시카드 위치 저장/복원 (이미 구현됨)

## 📋 다음 단계

### GitHub Repository 설정
1. GitHub에 새 저장소 생성: https://github.com/JIHUNJO123/hskmaster
2. 코드 푸시:
```bash
cd c:\Users\hooni\Desktop\hsk_vocab_app
git init
git add .
git commit -m "Initial commit for HSK Master"
git remote add origin https://github.com/JIHUNJO123/hskmaster.git
git branch -M main
git push -u origin main
```

### GitHub Pages 활성화
1. GitHub 저장소 Settings → Pages
2. Source: Deploy from a branch
3. Branch: main, Folder: /docs
4. Save

### iOS App Store Connect 설정
1. Apple Developer에서 번들 ID 등록: `com.jihunjo.hskmaster`
2. App Store Connect에서 새 앱 생성
3. 앱 정보:
   - 이름: HSK Master
   - 번들 ID: com.jihunjo.hskmaster
   - SKU: hskmaster_ios_001
   - 부제: Master Chinese Vocabulary for HSK
4. IAP 제품 생성:
   - 제품 ID: com.hskmaster.app.removeads
   - 가격: $1.99 USD
   - 이름: Remove Ads

### Google Play Console 설정
1. 새 앱 생성
2. 앱 세부정보:
   - 앱 이름: HSK Master
   - 패키지명: com.jihunjo.hskmaster
3. IAP 제품 생성:
   - 제품 ID: com.hskmaster.app.removeads
   - 가격: $1.99 USD

### 빌드 및 배포
```bash
# Android AAB 빌드
flutter build appbundle --release

# iOS 빌드
flutter build ipa --release
```

## 📞 연락처
- 이메일: jihun.jo@yahoo.com

## 🔗 링크
- GitHub: https://github.com/JIHUNJO123/hskmaster
- 개인정보처리방침: https://jihunjo123.github.io/hskmaster/privacy.html
- 고객 지원: https://jihunjo123.github.io/hskmaster/support.html

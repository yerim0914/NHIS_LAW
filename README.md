# NHIS_LAW 인수인계

국민건강보험법 및 노인장기요양보험법 학습용 Flutter MVP입니다. 서버, Firebase, 로그인, 결제, 실제 광고 SDK 없이 로컬 JSON과 `SharedPreferences`만 사용합니다.

## 현재 상태

- Flutter 프로젝트 생성 완료
- Android 릴리즈 APK 빌드 성공
- Flutter Web 빌드 성공
- 법령 데이터 적용 완료
  - 국민건강보험법: 147개 조문
  - 노인장기요양보험법: 91개 조문
  - 총 238개 조문
- 퀴즈 데이터 적용 완료
  - OX: 16문제
  - 객관식: 405문제
  - 총 421문제
- `flutter analyze` 통과
- `flutter test` 통과

## 로컬 환경

현재 작업 환경 기준 Flutter SDK 위치:

```powershell
D:\dev\flutter
```

새 터미널에서 `flutter`가 안 잡히면 아래처럼 전체 경로로 실행하세요.

```powershell
D:\dev\flutter\bin\flutter.bat --version
```

Android 빌드 중 Kotlin incremental cache가 한글 사용자 경로 때문에 실패한 이력이 있어 `android/gradle.properties`에 아래 설정을 추가했습니다.

```properties
kotlin.incremental=false
```

## 실행

```powershell
cd D:\Source\NHIS_LAW
D:\dev\flutter\bin\flutter.bat pub get
D:\dev\flutter\bin\flutter.bat run -d chrome
```

Android 기기나 에뮬레이터가 연결되어 있으면:

```powershell
cd D:\Source\NHIS_LAW
D:\dev\flutter\bin\flutter.bat devices
D:\dev\flutter\bin\flutter.bat run
```

## 빌드 산출물

Android APK:

```text
D:\Source\NHIS_LAW\build\app\outputs\flutter-apk\app-release.apk
```

아이폰에서 볼 수 있는 Flutter Web 배포 ZIP:

```text
D:\Source\NHIS_LAW\build\nhis_law_web.zip
```

웹 빌드 폴더:

```text
D:\Source\NHIS_LAW\build\web
```

iOS `.ipa`는 Windows에서 만들 수 없습니다. macOS, Xcode, Apple Developer 계정이 필요합니다. 현재 아이폰 확인용으로는 Flutter Web/PWA 배포가 현실적인 경로입니다.

## iOS 설치 파일 배포

아이폰에 설치 가능한 `.ipa`는 macOS에서 Xcode와 Apple Developer 서명을 사용해 빌드해야 합니다.
현재 프로젝트의 iOS Bundle ID는 아래 값입니다.

```text
com.nhis.study.nhisLaw
```

### 준비물

- Xcode 설치
- Flutter SDK 설치 및 `flutter` PATH 설정
- Apple Developer 계정
- Xcode `Runner` 타겟의 Signing & Capabilities에서 Team 선택

Xcode 프로젝트 열기:

```bash
open ios/Runner.xcworkspace
```

### TestFlight/App Store용 IPA

```bash
cd /Users/yerim/Documents/Codex/NHIS_LAW
chmod +x scripts/build_ios_ipa.sh
scripts/build_ios_ipa.sh app-store
```

빌드가 성공하면 아래 경로에 `.ipa`가 생성됩니다.

```text
build/ios/ipa/
```

생성된 `.ipa`는 Apple Transporter 또는 Xcode Organizer를 통해 App Store Connect에 업로드한 뒤 TestFlight로 배포합니다.

### Ad Hoc 직접 설치용 IPA

Ad Hoc은 설치할 iPhone의 UDID를 Apple Developer 계정에 먼저 등록해야 합니다.

```bash
cd /Users/yerim/Documents/Codex/NHIS_LAW
chmod +x scripts/build_ios_ipa.sh
scripts/build_ios_ipa.sh ad-hoc
```

Ad Hoc 설치가 실패하면 대부분 아래 중 하나입니다.

- iPhone UDID가 Apple Developer 계정에 등록되지 않음
- Bundle ID와 provisioning profile이 다름
- Xcode Signing Team이 선택되지 않음
- 인증서 또는 provisioning profile 만료

## 주요 기능

- 홈
  - 오늘의 학습
  - 최근 학습 조문
  - 주요 기능 바로가기
- 법령 보기
  - `법령 -> 장 -> 조문` 3단 접기 구조
  - 장 단위 OX/객관식 퀴즈 시작 버튼
  - 조문 북마크
- 조문 상세
  - 조문 본문 표시
  - 북마크 토글
  - 관련 OX/객관식 퀴즈 시작
  - 이전 조문/다음 조문 이동
- 검색
  - 법령명, 조문 번호, 제목, 본문 검색
  - 검색어 하이라이트
- 퀴즈
  - OX / 객관식 분리
  - 법령 장 단위 필터
  - 조문 단위 필터
  - 정답/오답 표시
  - 다시 풀기
  - 다음 문제가 없으면 `다음 문제` 버튼 비활성화
  - 오답이면 오답노트에 저장
- 오답노트
  - 틀린 문제 목록
  - 문제별 다시 풀기
  - 개별 삭제
  - 전체 삭제
- 북마크
  - 북마크 조문 목록
  - 상세 이동
- 설정
  - 앱 정보
  - 글자 크기 조절
  - 오답노트 초기화
  - 북마크 초기화
- 광고 영역
  - 모든 주요 화면 하단에 `AdPlaceholder`
  - 실제 AdMob 연동 시 `lib/main.dart`의 `AdPlaceholder`만 교체하는 방향

## 데이터

조문 데이터:

```text
assets/data/articles.json
```

퀴즈 데이터:

```text
assets/data/questions.json
```

데이터 모델은 현재 `lib/main.dart` 안에 있습니다.

### Article

- `id`
- `lawId`
- `lawName`
- `articleNumber`
- `title`
- `content`
- `chapter`
- `summary`

### Question

- `id`
- `type`: `ox` 또는 `multiple`
- `articleId`
- `question`
- `answer`
- `options`
- `explanation`

## 데이터 재생성

PDF에서 조문 JSON 재생성:

```powershell
cd D:\Source\NHIS_LAW
C:\Users\우태\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe tools\extract_law_articles.py
```

조문 JSON 기준 퀴즈 JSON 재생성:

```powershell
cd D:\Source\NHIS_LAW
C:\Users\우태\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe tools\generate_questions.py
```

주의: `extract_law_articles.py`는 사용자의 Downloads 폴더에 있는 아래 PDF 경로를 직접 참조합니다.

```text
C:\Users\우태\Downloads\3._(별첨2)_직무시험_관련_국민건강보험법_및_노인장기요양법\(법률 제21065호) 국민건강보험법_20251001.pdf
C:\Users\우태\Downloads\3._(별첨2)_직무시험_관련_국민건강보험법_및_노인장기요양법\(법률 제21257호) 노인장기요양보험법_20251230.pdf
```

PDF 위치가 바뀌면 `tools/extract_law_articles.py`의 `SOURCES`를 수정해야 합니다.

## 퀴즈 생성 정책

자동 생성 퀴즈는 완벽한 출제 엔진이 아닙니다. 사용자가 OX 품질에 민감하게 피드백했기 때문에 현재 정책은 보수적으로 잡혀 있습니다.

- 객관식은 조문별 최대 3개 항목을 생성합니다.
- OX는 억지 문항을 줄이기 위해 일부 제목만 생성합니다.
- OX 허용 제목:
  - 가입자의 종류
  - 자격의 취득 시기 등
  - 자격의 상실 시기 등
  - 요양급여
  - 급여의 제한
  - 급여의 정지
  - 장기요양급여의 종류
  - 급여외행위의 제공 금지
  - 장기요양기관의 지정
- OX로 만들기 애매한 조문은 문제를 만들지 않습니다.

다음 작업자는 `tools/generate_questions.py`의 `should_make_ox`, `topic_distractors`, `question_stem`을 우선 조정하면 됩니다.

## 검증 명령

```powershell
cd D:\Source\NHIS_LAW
D:\dev\flutter\bin\flutter.bat analyze
```

테스트는 한글 사용자 경로 때문에 Windows `flutter_tester`가 불안정할 때가 있어 ASCII 임시 폴더를 지정합니다.

```powershell
cd D:\Source\NHIS_LAW
$env:TEMP='D:\Source\NHIS_LAW\.tmp'
$env:TMP='D:\Source\NHIS_LAW\.tmp'
D:\dev\flutter\bin\flutter.bat test
```

웹 빌드:

```powershell
cd D:\Source\NHIS_LAW
D:\dev\flutter\bin\flutter.bat build web
```

APK 빌드:

```powershell
cd D:\Source\NHIS_LAW
D:\dev\flutter\bin\flutter.bat build apk
```

## 알려진 주의점

- 현재 모든 앱 코드가 `lib/main.dart` 한 파일에 모여 있습니다. 기능이 커졌으므로 다음 작업에서는 `models/`, `repositories/`, `screens/`, `widgets/`로 분리하는 리팩터링이 좋습니다.
- 퀴즈는 자동 생성 기반이라 실제 시험 품질로 쓰려면 사람이 검수하거나 별도 출제 로직을 더 강화해야 합니다.
- OX는 일부 조문만 생성됩니다. 애매한 OX는 일부러 삭제하는 정책입니다.
- 객관식 오답 보기는 아직 완전히 자연스럽지 않을 수 있습니다.
- Android APK는 debug signing이 아닌 Flutter 기본 release build 산출물이지만, Play Store 배포용 서명 설정은 아직 하지 않았습니다.
- 실제 광고 SDK는 붙어 있지 않습니다.
- iOS 앱 빌드는 macOS/Xcode에서 별도 진행해야 합니다.

## 다음 작업 추천

1. `lib/main.dart` 파일 분리
2. 객관식 퀴즈 품질 개선
3. 장별 학습 진행률 표시
4. 오답노트에서 장/법령 필터 추가
5. 북마크/오답 데이터 export/import
6. AdMob 연동 시 `AdPlaceholder` 교체
7. Play Store 배포용 앱 아이콘, 앱 이름, signing 설정

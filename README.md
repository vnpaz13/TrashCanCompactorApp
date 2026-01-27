卒業操作

iOSアプリとArduinoをBLE（HM-10）で連携させ、ごみ箱圧縮機のモーターを遠隔操作できるシステム

iPhoneアプリから“圧縮開始”コマンドを送信し、Arduino上のBLDCモーターが約30秒間の圧縮サイクルを実行

安全性確保のため、圧縮動作中の重複コマンド防止やステータス表示などの制御機能も実装

# 🗑️ TrashCompactor iOS App

TrashCompactor는 iOS 앱에서 **Bluetooth Low Energy (BLE)** 를 이용해  
**Arduino + HM-10 모듈**과 통신하여 압축기 구동을 실현하는 프로젝트입니다.

사용자는 앱을 통해 블루투스 연결을 수행한 후,  
버튼 클릭만으로 쓰레기 압축 동작을 실행할 수 있습니다.

---

## 🔧 주요 기능

- 🔵 HM-10 BLE 모듈 자동 스캔 및 연결
- 📡 BLE 명령 전송을 통한 압축 동작 제어
- ⏱ 압축 동작 중 상태 관리 및 중복 실행 방지
- 🧪 Test Mode 지원 (BLE 하드웨어 없이 앱 테스트 가능)
- 📱 UIKit 기반의 단순하고 직관적인 UI

---

## 🧠 프로젝트 구조

### BLEMotorManager
- CoreBluetooth 기반 BLE 통신 관리자
- HM-10 디바이스 검색 및 연결 관리
- 서비스(FFE0) 및 캐릭터리스틱(FFE1) 탐색
- 압축 시작 명령 `"C"` 전송
- Test Mode 제공 (실제 BLE 통신 없이 로직 테스트 가능)

### ViewController
- 사용자 인터페이스(UI) 구성 및 버튼 이벤트 처리
- BLE 연결 상태 및 압축 진행 상태 표시
- 압축 동작 중 중복 명령 방지
- Arduino 동작 시간 기준 타이머를 이용한 압축 완료 처리

---

## ⚙️ 사용 기술

- UIKit
- SnapKit
- CoreBluetooth
- Bluetooth Low Energy (BLE)
- Arduino (외부 하드웨어 연동)

---

## 🧪 Test Mode 사용 방법

BLE 하드웨어가 없는 환경에서도 앱 테스트가 가능하도록  
Test Mode를 지원합니다.

```swift
bleManager.isTestMode = true

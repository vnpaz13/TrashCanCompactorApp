卒業操作

iOSアプリとArduinoをBLE（HM-10）で連携させ、ごみ箱圧縮機のモーターを遠隔操作できるシステム

iPhoneアプリから“圧縮開始”コマンドを送信し、Arduino上のBLDCモーターが約30秒間の圧縮サイクルを実行

安全性確保のため、圧縮動作中の重複コマンド防止やステータス表示などの制御機能も実装

🗑️ TrashCompactor iOS App

TrashCompactor는
iOS 앱에서 Bluetooth Low Energy(BLE) 를 통해 Arduino + HM-10 모듈과 통신하여
쓰레기통 압축기를 원격으로 제어하는 프로젝트입니다.

사용자는 앱에서 블루투스를 통해 장치에 연결한 뒤,
버튼 한 번으로 쓰레기 압축 동작을 실행할 수 있습니다.

🔧 주요 기능

🔵 HM-10 BLE 모듈 자동 스캔 및 연결

📡 BLE 명령 전송을 통한 압축 시작 제어

⏱ 압축 동작 중 상태 관리 및 중복 실행 방지

🧪 Test Mode 지원 (BLE 없이 앱 동작 테스트 가능)

📱 UIKit 기반의 단순하고 직관적인 UI

🧠 구조 개요
BLEMotorManager

CoreBluetooth 기반 BLE 통신 관리자

HM-10 디바이스 스캔 및 연결

특정 Characteristic(FFE1)에 명령("C") 전송

테스트 모드 제공으로 실제 BLE 없이 앱 로직 검증 가능

ViewController

사용자 인터페이스 및 버튼 이벤트 처리

BLE 연결 상태 및 압축 진행 상태 표시

압축 동작 중 중복 명령 방지

압축 완료 타이머 처리 (Arduino 동작 시간 기준)

⚙️ 사용 기술

Swift

UIKit

CoreBluetooth

BLE (HM-10)

Arduino (외부 하드웨어 연동)

🧪 Test Mode

BLE 하드웨어가 없는 환경에서도 앱 테스트가 가능하도록
BLEMotorManager에 Test Mode를 제공합니다.

bleManager.isTestMode = true


Test Mode 활성화 시:

실제 BLE 스캔/연결 없이 즉시 연결 상태로 전환

BLE 명령 전송은 로그 출력으로 대체

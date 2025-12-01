//
//  BluetoothManager.swift
//  TrashCompactor
//
//  Created by VnPaz on 12/1/25.
//

import Foundation
import CoreBluetooth

// HM-10을 찾아서 연결하고, 압축 동작을 수행하도록 아두이노에게 전달하는 관리자
class BLEMotorManager: NSObject {

    static let shared = BLEMotorManager()

    private var central: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?

    private let serviceUUID = CBUUID(string: "FFE0")
    private let charUUID    = CBUUID(string: "FFE1")

    // 테스트 모드 플래그 (true면 실제 BLE 없이 시뮬레이션만 함)
    var isTestMode: Bool = false

    // 외부에서 상태를 보고 싶을 때 쓸 콜백들
    var onLog: ((String) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?

    // 연결 상태
    private(set) var isConnected: Bool = false {
        didSet {
            onConnectionStateChanged?(isConnected)
        }
    }

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    // ViewController에서 "블루투스 연결" 버튼 눌렀을 때 호출
    func startScan() {
        //  테스트 모드일 때: 실제 스캔 안 하고 바로 연결된 것처럼 처리
        if isTestMode {
            onLog?("[TEST] 실제 스캔 없이 '연결 완료' 상태로 설정합니다.")
            isConnected = true
            return
        }

        guard central.state == .poweredOn else {
            onLog?("Bluetooth가 꺼져 있거나 사용 불가 상태입니다.")
            return
        }
        onLog?("HM-10 스캔 시작…")
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    // 압축 시작 명령 ("C") 보내기
    func sendStartCycle() {
        sendCommand("C")
    }

    private func sendCommand(_ text: String) {

        // 테스트 모드일 때: 실제 BLE write 대신 로그만 찍고 종료
        if isTestMode {
            onLog?("[TEST] '\(text)' 명령을 전송했다고 가정합니다. (실제 BLE 전송 없음)")
            return
        }

        guard isConnected,
              let peripheral = targetPeripheral,
              let characteristic = writeCharacteristic,
              let data = text.data(using: .utf8) else {
            onLog?("아직 HM-10과 통신할 준비가 안 되어 있습니다.")
            return
        }

        onLog?("명령 전송: \(text)")
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CoreBluetooth Delegate

extension BLEMotorManager: CBCentralManagerDelegate, CBPeripheralDelegate {

    // 블루투스 상태 변경
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 테스트 모드에서는 실제 BLE 상태와 관계 없이 isConnected를 우리가 제어하니,
        // 여기서는 로그만 찍어도 됨
        switch central.state {
        case .poweredOn:
            onLog?("Bluetooth ON (사용 가능)")
        case .poweredOff:
            onLog?("Bluetooth OFF")
            if !isTestMode {
                isConnected = false
            }
        default:
            onLog?("Bluetooth 상태: \(central.state.rawValue)")
        }
    }

    // 주변 기기 발견
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        if isTestMode { return } // 테스트 모드면 실제 연결 로직 무시

        // HM-10 이름 (수정 가능)
        if let name = peripheral.name, name.contains("HMSoft") {
            onLog?("HM-10 발견: \(name)")
            targetPeripheral = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }

    // 연결 성공
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        if isTestMode { return }

        onLog?("HM-10 연결 성공")
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    // 연결 끊김
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if isTestMode { return }

        onLog?("HM-10 연결 끊김")
        isConnected = false
        targetPeripheral = nil
        writeCharacteristic = nil
    }

    // 서비스 발견
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if isTestMode { return }

        if let error = error {
            onLog?("서비스 검색 에러: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            onLog?("서비스 발견, 캐릭터리스틱 검색…")
            peripheral.discoverCharacteristics([charUUID], for: service)
        }
    }

    // 캐릭터리스틱 발견
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if isTestMode { return }

        if let error = error {
            onLog?("캐릭터리스틱 검색 에러: \(error.localizedDescription)")
            return
        }

        guard let chars = service.characteristics else { return }
        for ch in chars where ch.uuid == charUUID {
            writeCharacteristic = ch
            onLog?("HM-10과 통신 준비 완료 (명령 전송 가능)")
        }
    }
}

//
//  ViewController.swift
//  TrashCompactor
//
//  Created by VnPaz on 12/1/25.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    // MARK: - UI
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let bleButton = UIButton()
    private let compactButton = UIButton()
    
    // BLE 매니저
    private let bleManager = BLEMotorManager.shared
    
    // 압축 동작 중인지 여부
    private var isCompressing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test모드 사용 시 활성화 필요
        // bleManager.isTestMode = true
        
        view.backgroundColor = .white
        
        setupUI()
        setupBLECallbacks()
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 1) 타이틀 라벨 설정
        titleLabel.text = "쓰레기통 압축기 앱"
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 35)
        
        // 2) 상태 라벨 설정
        statusLabel.text = "연결 대기중"
        statusLabel.textColor = .black
        statusLabel.textAlignment = .center
        statusLabel.font = .boldSystemFont(ofSize: 30)
        
        // 3) BLE 버튼 설정
        bleButton.setTitle("블루투스 연결", for: .normal)
        bleButton.setTitleColor(.white, for: .normal)
        bleButton.backgroundColor = .blue
        bleButton.layer.cornerRadius = 12
        bleButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        bleButton.addTarget(self, action: #selector(handleBleButton), for: .touchUpInside)
        
        // 4) 압축 버튼 설정
        compactButton.setTitle("압축", for: .normal)
        compactButton.setTitleColor(.white, for: .normal)
        compactButton.backgroundColor = .systemGreen
        compactButton.layer.cornerRadius = 12
        compactButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        compactButton.addTarget(self, action: #selector(handleCompactButton), for: .touchUpInside)
        
        // 5) addSubview
        view.addSubview(titleLabel)
        view.addSubview(statusLabel)
        view.addSubview(bleButton)
        view.addSubview(compactButton)
        
        // 6) SnapKit Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top).offset(120)
            make.centerX.equalToSuperview()
        }
        
        bleButton.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(60)
            make.leading.equalToSuperview().offset(40)
            make.width.equalTo(150)
            make.height.equalTo(bleButton.snp.width)
        }
        
        compactButton.snp.makeConstraints { make in
            make.centerY.equalTo(bleButton.snp.centerY)
            make.trailing.equalToSuperview().inset(40)
            make.width.equalTo(bleButton.snp.width)
            make.height.equalTo(bleButton.snp.height)
        }
    }
    
    // MARK: - BLE 콜백
    
    private func setupBLECallbacks() {
        // 연결 상태 변경
        bleManager.onConnectionStateChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // 압축 중일 때는 상태 문구를 바꾸지 않는다
                if self.isCompressing {
                    return
                }
                
                if isConnected {
                    self.statusLabel.text = "연결 완료"
                    self.statusLabel.textColor = .systemGreen
                } else {
                    self.statusLabel.text = "연결 대기중"
                    self.statusLabel.textColor = .black
                }
            }
        }
        
        bleManager.onLog = { text in
            print("[BLE]", text)
        }
    }
    
    // MARK: - 버튼 액션
    
    @objc private func handleBleButton() {
        bleManager.startScan()
    }
    
    @objc private func handleCompactButton() {
        // 1) BLE 연결 체크
        if !bleManager.isConnected {
            let alert = UIAlertController(
                title: "연결 오류",
                message: "압축기와 연결이 되지 않았습니다!\n다시 시도해주세요!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 2) 이미 압축 동작 중이면 → 경고만 띄우고 C 명령 보내지 않음
        if isCompressing {
            let alert = UIAlertController(
                title: "압축 수행중",
                message: "압축 수행중이므로, 잠시후 다시 시도해주세요",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 3) 이제 실제로 압축 시작
        isCompressing = true
        statusLabel.text = "압축 동작 수행중"
        statusLabel.textColor = .systemBlue
        
        // HM-10으로 "C" 명령 전송 (아두이노로 압축 시작)
        bleManager.sendStartCycle()
        
        // 4) 약 31초 뒤에 압축 완료로 상태 변경 (아두이노 코드 기준)
        Timer.scheduledTimer(withTimeInterval: 31.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isCompressing = false
            
            // 압축이 끝난 것으로 간주 → 상태 문구 변경
            self.statusLabel.text = "압축 완료!"
            self.statusLabel.textColor = .systemPurple
        }
    }
}

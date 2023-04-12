//
//  OutputDevices.swift
//  Quality
//
//  Created by Vincent Neo on 20/4/22.
//

import Combine
import Foundation
import SimplyCoreAudio

class OutputDevices: ObservableObject {
    @Published var defaultOutputDevice: AudioDevice?
    @Published var outputDevices = [AudioDevice]()
    @Published var currentSampleRate: Float64?
    @Published var detectedSampleRate: Float64?
    @Published var supportedSampleRates: [Float64] = []
    
    private var lastNearestSampleRate: Float64?
    
    private let coreAudio = SimplyCoreAudio()
    
    private var changesCancellable: AnyCancellable?
    private var defaultChangesCancellable: AnyCancellable?
    
    var enableAutoSwitch = Defaults.shared.userPreferAutoSwitch
    private var enableAutoSwitchCancellable: AnyCancellable?
    
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    private var timerCancellable: AnyCancellable?
    private var consoleQueue = DispatchQueue(label: "consoleQueue", qos: .userInteractive)
    
    init() {
        self.outputDevices = self.coreAudio.allOutputDevices
        self.defaultOutputDevice = self.coreAudio.defaultOutputDevice
        self.getDeviceSampleRate()
        self.updateSupportedSampleRates()
        
        changesCancellable =
        NotificationCenter.default.publisher(for: .deviceListChanged).sink(receiveValue: { _ in
            self.outputDevices = self.coreAudio.allOutputDevices
        })
        
        defaultChangesCancellable =
        NotificationCenter.default.publisher(for: .defaultOutputDeviceChanged).sink(receiveValue: { _ in
            self.defaultOutputDevice = self.coreAudio.defaultOutputDevice
            self.getDeviceSampleRate()
            self.updateSupportedSampleRates()
            AppDelegate.instance.updateClients()
        })
        
        timerCancellable = timer.sink(receiveValue: { _ in
            self.consoleQueue.async {
                self.switchLatestSampleRate()
            }
        })
        
        enableAutoSwitchCancellable = Defaults.shared.$userPreferAutoSwitch.sink(receiveValue: { newValue in
            self.enableAutoSwitch = newValue
            AppDelegate.instance.updateClients()
        })
    }
    
    deinit {
        changesCancellable?.cancel()
        defaultChangesCancellable?.cancel()
        timerCancellable?.cancel()
        timer.upstream.connect().cancel()
        enableAutoSwitchCancellable?.cancel()
    }
    
    func getDeviceSampleRate() {
        let defaultDevice = self.defaultOutputDevice
        guard let sampleRate = defaultDevice?.nominalSampleRate else { return }
        self.updateSampleRate(sampleRate, force: true)
    }
    
    func switchLatestSampleRate() {
        do {
            let musicLog = try Console.getRecentEntries()
            let cmStats = CMPlayerParser.parseMusicConsoleLogs(musicLog)
            
            let defaultDevice = self.defaultOutputDevice
            if let first = cmStats.first, let supported = defaultDevice?.nominalSampleRates {
                let sampleRate = Float64(first.sampleRate)
                // https://stackoverflow.com/a/65060134
                let nearest = supported.enumerated().min(by: {
                    abs($0.element - sampleRate) < abs($1.element - sampleRate)
                })
                if let nearest = nearest {
                    let nearestSampleRate = nearest.element
                    self.lastNearestSampleRate = nearestSampleRate
                    //if nearestSampleRate != defaultDevice?.nominalSampleRate {
                    if enableAutoSwitch {
                        defaultDevice?.setNominalSampleRate(nearestSampleRate)
                    }
                    self.updateSampleRate(nearestSampleRate)
                    //}
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    func setDeviceSampleRate(_ sampleRate: Float64?) {
        if let targetSampleRate = sampleRate ?? lastNearestSampleRate {
            if targetSampleRate > 1000 {
                if defaultOutputDevice?.nominalSampleRate != targetSampleRate {
                    //print("Setting device sample rate to \(targetSampleRate)")
                    defaultOutputDevice?.setNominalSampleRate(targetSampleRate)
                }
                updateSampleRate(targetSampleRate, force: true)
            }
        }
    }
    
    func updateSampleRate(_ sampleRate: Float64, force: Bool = false) {
        DispatchQueue.main.async {
            let readableSampleRate = sampleRate / 1000
            if self.enableAutoSwitch || force {
                self.currentSampleRate = readableSampleRate
            }
            let detectedSampleRate = self.lastNearestSampleRate ?? 1.0
            let readableCurrentSampleRate = self.currentSampleRate ?? detectedSampleRate / 1000
            let readableDetectedSampleRate = detectedSampleRate / 1000
            if self.detectedSampleRate != readableSampleRate
            {
                self.detectedSampleRate = readableDetectedSampleRate
                AppDelegate.instance.updateClients()
            }
            
            let delegate = AppDelegate.instance
            delegate?.statusItemTitle = String(format: "C:%.1f | D:%.1f kHz", readableCurrentSampleRate, readableDetectedSampleRate)
        }
    }
    
    func updateSupportedSampleRates() {
        if let device = defaultOutputDevice, let rates = device.nominalSampleRates {
            supportedSampleRates = rates.map { Double($0) / 1000 }
        } else {
            supportedSampleRates = []
        }
    }

}

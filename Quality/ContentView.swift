//
//  ContentView.swift
//  Quality
//
//  Created by Vincent Neo on 18/4/22.
//

import SwiftUI
import OSLog
import SimplyCoreAudio

struct ContentView: View {
    @EnvironmentObject var outputDevices: OutputDevices
    
    var body: some View {
        VStack {
            if let currentSampleRate = outputDevices.currentSampleRate {
                let formattedSampleRate = String(format: "C: %.1f kHz", currentSampleRate)
                Text(formattedSampleRate)
                    .font(.system(size: 23, weight: .semibold, design: .default))
            }
            if let detectedSampleRate = outputDevices.detectedSampleRate {
                let formattedDetectedSampleRate = String(format: "D: %.1f kHz", detectedSampleRate)
                Text(formattedDetectedSampleRate)
                    .font(.system(size: 23, weight: .semibold, design: .default))
            }
            if let device = outputDevices.defaultOutputDevice {
                Text(device.name)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



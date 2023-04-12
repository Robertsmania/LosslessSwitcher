//
//  Defaults.swift
//  Quality
//
//  Created by Vincent Neo on 23/4/22.
//

import Foundation

class Defaults {
    static let shared = Defaults()
    private let kUserPreferIconStatusBarItem = "com.vincent-neo.LosslessSwitcher-Key-UserPreferIconStatusBarItem"
    private let kUserPreferAutoSwitch = "com.vincent-neo.LosslessSwitcher-Key-AutoSwitch"
    @Published var userPreferAutoSwitch: Bool
    
    private init() {
        UserDefaults.standard.register(defaults: [
            kUserPreferIconStatusBarItem : true,
            kUserPreferAutoSwitch : true
        ])

        self.userPreferAutoSwitch = UserDefaults.standard.bool(forKey: kUserPreferAutoSwitch)
    }
    
    var userPreferIconStatusBarItem: Bool {
        get {
            return UserDefaults.standard.bool(forKey: kUserPreferIconStatusBarItem)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kUserPreferIconStatusBarItem)
        }
    }
    
    var statusBarItemTitle: String {
        let title = self.userPreferIconStatusBarItem ? "Show Sample Rate" : "Show Icon"
        return title
    }
    
    func setPreferAutoSwitch(newValue: Bool) {
        UserDefaults.standard.set(newValue, forKey: kUserPreferAutoSwitch)
        self.userPreferAutoSwitch = newValue
    }
}

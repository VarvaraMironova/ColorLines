//
//  VMTimer.swift
//  VMLines
//
//  Created by Varvara Myronova on 08.02.2021.
//

import Foundation

extension VMTimer {
    enum kVMTimerState {
        case running
        case suspend
        case stopped
    }
}

class VMTimer {
    private var timer      : Timer!
    private var startTime  : Date?
    private var state      : kVMTimerState?

    private var elapsedTime : TimeInterval {
        if let startTime = startTime {
            return -startTime.timeIntervalSinceNow
        } else {
            return 0
        }
    }
    
    public var elapsedTimeAsString: String {
        return String(format: "%02d:%02d.%d",
            Int(elapsedTime / 60), Int(elapsedTime.truncatingRemainder(dividingBy: 60)), Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10)))
    }
    
    init(game: VMGame) {
        timer = Timer.scheduledTimer(timeInterval : 0.1,
                                     target       : game,
                                     selector     : #selector(VMGame.updateTimer),
                                     userInfo     : nil,
                                     repeats      : true)
        startTime = Date()
        state = .running
    }
    
    func suspend() {
        
    }
    
    func resume() {
        
    }
    
    public func stop() {
        timer.invalidate()
        state = .stopped
        startTime = nil
    }
}

//
//  EventThrottler.swift
//  Editor
//
//  Created by pmacro  on 30/01/2019.
//

import Foundation

class EventThrottler {
  var timer: RepeatingTimer
  typealias EventAction = () -> Void
  let interval: TimeInterval
  var action: EventAction?
  
  var removeActionAfterInvocation = true
  var pauseWhenIdle = true
  
  init(schedule: TimeInterval) {
    self.interval = schedule
    timer = RepeatingTimer(timeInterval: schedule)
    self.schedule(at: interval)
  }
  
  private func schedule(at schedule: TimeInterval) {
    timer.eventHandler = {
      DispatchQueue.main.sync {
        if self.pauseWhenIdle, self.action == nil { self.timer.suspend() }
        self.action?()
        if self.removeActionAfterInvocation {
          self.action = nil
        }
      }
    }
  
    timer.resume()
  }
  
  func add(_ action: @escaping EventAction) {
    self.action = action
    
    if pauseWhenIdle {
      self.timer.resume()
    }
  }
}

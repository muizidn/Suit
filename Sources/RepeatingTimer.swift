
import Foundation

extension RepeatingTimer: AnimationTimer {
  
  var callback: (() -> Void)? {
    set {
      eventHandler = newValue
    }
    
    get {
      return eventHandler
    }
  }
  
  func start() {
    resume() 
  }
  
  func stop() {
    suspend()
  }
  
  static func create() -> AnimationTimer {
    return RepeatingTimer(timeInterval: AnimationInterval)
  }
}

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
open class RepeatingTimer {
  
  let background = DispatchQueue(label: "backgroundTimer",
                                 qos: .userInteractive,
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
  
  let timeInterval: TimeInterval
  
  public init(timeInterval: TimeInterval) {
    self.timeInterval = timeInterval
  }
  
  var suspendUntil: Date?

  private lazy var timer: DispatchSourceTimer = {
    let t = DispatchSource.makeTimerSource(flags: .strict, queue: background)
    t.schedule(wallDeadline: DispatchWallTime.now() + self.timeInterval,
               repeating: self.timeInterval,
               leeway: DispatchTimeInterval.milliseconds(1))
    
    t.setEventHandler(handler: { [weak self] in
      if let resumeDate = self?.suspendUntil {
        if resumeDate < Date() {
          self?.suspendUntil = nil
        } else {
          return
        }
      }
      self?.eventHandler?()
    })
    return t
  }()
  
  open var eventHandler: (() -> Void)?
  
  private enum State {
    case suspended
    case resumed
  }
  
  private var state: State = .suspended
  
  deinit {
    timer.setEventHandler {}
    timer.cancel()
    /*
     If the timer is suspended, calling cancel without resuming
     triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
     */
    resume()
    eventHandler = nil
  }
  
  open func resume() {
    if state == .resumed {
      return
    }
    state = .resumed
    timer.resume()
  }
  
  open func suspend() {
    if state == .suspended {
      return
    }
    state = .suspended
    timer.suspend()
  }
  
  open func suspend(for duration: TimeInterval) {
    suspendUntil = Date().addingTimeInterval(duration)
  }
}

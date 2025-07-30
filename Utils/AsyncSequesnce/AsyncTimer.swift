import Foundation
import AsyncAlgorithms


/*
 NOTE: current timers implementation uses clock of type ContinuousClock.
 
 ContinuousClock: In this case, the timer tracks real time: if the app has been in the background for
 a certain period, upon returning it can immediately generate several “missed” events at once or
 instantly “catch up” to the current time. But the key point is — while the app is suspended,
 the execution of your code in the Task is paused (regardless of the clock).
 
 If the timer needs to work only in foreground mode, create an implementation using a clock of type SuspendedClock.
 */


// MARK: - Async timer

final class AsyncTimer: Sendable
{
    private let baseTimer: BaseCountdownAsyncTimer
    
    public init(id: String? = nil) {
        self.baseTimer = .init(id: id)
    }
    
    deinit {
        self.stop()
    }
    
    public func start(
        withIntervalInSec interval: Int = 1,
        startDelayInSeconds: Int = 0,
        iterationAction: @Sendable @escaping () -> Void
    ) {
        Task { [weak timer = self.baseTimer] in
            try? await Task.sleep(for: .seconds(startDelayInSeconds))
            await timer?.start(
                withIntervalInSec: interval,
                startDelayInSeconds: startDelayInSeconds,
                iterationAction:  { _ in
                    iterationAction()
            })
        }
    }
    
    public func stop() {
        self.baseTimer.stop()
    }
    
    public func pause(_ isOnPause: Bool) {
        self.baseTimer.pause(isOnPause)
    }
}


// MARK: - Countdown async timer

final class AsyncСountdownTimer
{
    private let baseTimer: BaseCountdownAsyncTimer
    
    public init(id: String? = nil) {
        self.baseTimer = .init(id: id)
    }
    
    deinit {
        self.stop()
    }
    
    public func start(
        withIntervalInSec interval: Int = 1,
        remainTimeInSeconds: Int,
        startDelayInSeconds: Int = 0,
        iterationAction: @Sendable @escaping (_ seconds: Int) -> Void,
        completionAction: (@Sendable () -> Void)? = nil
    ) {
        Task { [weak timer = self.baseTimer] in
            await timer?.start(
                withIntervalInSec: interval,
                remainTimeInSeconds: remainTimeInSeconds,
                startDelayInSeconds: startDelayInSeconds,
                iterationAction: { seconds in
                    guard let seconds  else { return }
                    iterationAction(seconds)
                },
                completionAction: completionAction
            )
        }
    }
    
    public func stop() {
        self.baseTimer.stop()
    }
    
    public func pause(_ isOnPause: Bool) {
        self.baseTimer.pause(isOnPause)
    }
}


// MARK: - Base countdown timer

fileprivate actor BaseCountdownAsyncTimer: Sendable
{
    private let id: String
    private var timerTask: Task<Void, Never>?
    private var remainTimeInSeconds: Int?
    private var isOnPause: Bool = false
    
    public init(id: String? = nil) {
        self.id = (id ?? "") + "_" + Self.randomID(length: 4)
        print("AsyncTimer init(), id - \(self.id)")
    }
    
    deinit {
        print("AsyncTimer deinit(), id - \(self.id)")
    }
    
    public func start(
        withIntervalInSec interval: Int = 1,
        remainTimeInSeconds: Int? = nil,
        startDelayInSeconds: Int = 0,
        iterationAction: @Sendable @escaping (_ seconds: Int?) -> Void,
        completionAction: (@Sendable () -> Void)? = nil
    ) {
        print("AsyncTimer started, id - \(self.id)")
        self.remainTimeInSeconds = remainTimeInSeconds
        self._stop()
        self.timerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(startDelayInSeconds))
            let timer = AsyncTimerSequence(interval: .seconds(interval), clock: .continuous)
            for await _ in timer {
                guard await self?.isOnPause == false else {
                    continue
                }
                // repeating until called stop() if remainTimeInSeconds == nil
                guard let seconds = await self?.remainTimeInSeconds else {
                    await iterationAction(self?.remainTimeInSeconds)
                    continue
                }
                if seconds > 0 {
                    self?.setRemainTime(seconds: seconds - 1)
                    await iterationAction(self?.remainTimeInSeconds)
                } else {
                    break
                }
            }
            completionAction?()
            await self?._stop()
        }
    }
    
    nonisolated
    private func setRemainTime(seconds: Int) {
        Task { [weak self] in
            await self?.setRemainTime(seconds)
        }
    }
    
    private func setRemainTime(_ remainTimeInSeconds: Int) {
        self.remainTimeInSeconds = remainTimeInSeconds
    }
    
    nonisolated
    func pause(_ isOnPause: Bool) {
        Task { [weak self] in
            await self?._pause(isOnPause)
        }
    }
    
    
    private func _pause(_ isOnPause: Bool) {
        self.isOnPause = isOnPause
        print("AsyncTimer on pause - \(isOnPause)")
    }
    
    nonisolated
    func stop() {
        Task { [weak self] in
            await self?._stop()
        }
    }
    
    private func _stop() {
        if self.timerTask != nil {
            self.timerTask?.cancel()
            self.timerTask = nil
            self.remainTimeInSeconds = nil
            print("AsyncTimer stoppped, id - \(self.id)")
        }
    }
    
    private static func randomID(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var s = ""
        for _ in 0 ..< length {
            s.append(letters.randomElement()!)
        }
        return s
    }
}

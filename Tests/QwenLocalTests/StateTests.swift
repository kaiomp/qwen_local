import Foundation
import Testing

@testable import QwenLocal

struct StateTests {
    let now = Date()

    @Test func notLoadedIsOff() {
        #expect(state(jobLoaded: false, healthCode: 200, loadingSince: nil, now: now) == .off)
    }

    @Test func loadedWithoutHealthIsLoading() {
        #expect(state(jobLoaded: true, healthCode: nil, loadingSince: now, now: now) == .loading)
        #expect(state(jobLoaded: true, healthCode: 503, loadingSince: now, now: now) == .loading)
    }

    @Test func loadedAndHealthyIsRunning() {
        #expect(state(jobLoaded: true, healthCode: 200, loadingSince: nil, now: now) == .running)
    }

    @Test func notReadyAfterFiveMinutesIsStuck() {
        let since = now.addingTimeInterval(-301)
        #expect(state(jobLoaded: true, healthCode: 503, loadingSince: since, now: now) == .stuck)
        #expect(
            state(jobLoaded: true, healthCode: 503, loadingSince: now.addingTimeInterval(-299), now: now) == .loading)
    }
}

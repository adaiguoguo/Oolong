import Testing
import Foundation
@testable import Oolong

struct ModelsTests {
    @Test func keepAwakeDurationSeconds() {
        #expect(KeepAwakeDuration.forever.seconds == nil)
        #expect(KeepAwakeDuration.hours(1).seconds == 3600)
        #expect(KeepAwakeDuration.hours(4).seconds == 14_400)
        #expect(KeepAwakeDuration.all.count == 4)
    }

    @Test func rateLimitWindowRemaining() {
        let future = RateLimitWindow(usedPercentage: 30, resetsAt: Date(timeIntervalSinceNow: 100))
        #expect(future.remaining > 95 && future.remaining <= 100)

        let past = RateLimitWindow(usedPercentage: 30, resetsAt: Date(timeIntervalSinceNow: -100))
        #expect(past.remaining == 0)
    }

    @Test func rateLimitInfoStale() {
        #expect(!RateLimitInfo(fiveHour: nil, sevenDay: nil, asOf: Date()).isStale)
        #expect(RateLimitInfo(fiveHour: nil, sevenDay: nil, asOf: Date(timeIntervalSinceNow: -200)).isStale)
    }

    @Test func fiveHourBlockRemainingClampsToZero() {
        let block = FiveHourBlock(tokens: 1, costUSD: 0, tokensPerMinute: 0,
                                  endTime: Date(timeIntervalSinceNow: -10))
        #expect(block.remaining == 0)
    }

    @Test func i18nResolve() {
        #expect(!I18n.resolve(.en))
        #expect(I18n.resolve(.zh))
    }
}

import Testing
import Foundation
@testable import Oolong

@Suite(.serialized)
struct FormattersTests {
    init() { I18n.isZH = false }

    @Test func tokens() {
        #expect(Fmt.tokens(0) == "0")
        #expect(Fmt.tokens(999) == "999")
        #expect(Fmt.tokens(27_700) == "27.7K")
        #expect(Fmt.tokens(74_900_000) == "74.9M")
        #expect(Fmt.tokens(1_500_000_000) == "1.5B")
    }

    @Test func cost() {
        #expect(Fmt.cost(0) == "$0.00")
        #expect(Fmt.cost(69.01) == "$69.01")
        #expect(Fmt.cost(159.768) == "$159.77")
    }

    @Test func burnRate() {
        #expect(Fmt.burnRate(271_300) == "271.3k tok/min")
        #expect(Fmt.burnRate(0) == "0.0k tok/min")
    }

    @Test func countdownClampsNegative() {
        #expect(Fmt.countdown(11_785) == "3:16:25")
        #expect(Fmt.countdown(0) == "0:00:00")
        #expect(Fmt.countdown(-5) == "0:00:00")
    }

    @Test func uptimeEnglish() {
        I18n.isZH = false
        #expect(Fmt.uptime(12_180) == "3h 23m")
        #expect(Fmt.uptime(2 * 86_400 + 3 * 3600) == "2d 3h")
    }

    @Test func uptimeChinese() {
        I18n.isZH = true
        #expect(Fmt.uptime(12_180) == "3小时 23分")
        I18n.isZH = false
    }

    @Test func shortDuration() {
        I18n.isZH = false
        #expect(Fmt.shortDuration(84_600) == "23h 30m")
        #expect(Fmt.shortDuration(90_000) == "1d 1h")
        #expect(Fmt.shortDuration(120) == "2m")
        #expect(Fmt.shortDuration(-10) == "0m")
    }

    @Test func gib() {
        #expect(Fmt.gib(20_937_965_568) == "19.5 GB")
        #expect(Fmt.gib(0) == "0.0 GB")
    }

    @Test func relativeAge() {
        I18n.isZH = false
        #expect(Fmt.relativeAge(nil) == "Not refreshed")
        #expect(Fmt.relativeAge(Date(timeIntervalSinceNow: -7)) == "Updated 7s ago")
        #expect(Fmt.relativeAge(Date(timeIntervalSinceNow: -300)) == "Updated 5m ago")
    }
}

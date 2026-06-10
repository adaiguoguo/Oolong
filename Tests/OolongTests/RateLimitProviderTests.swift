import Testing
import Foundation
@testable import Oolong

struct RateLimitProviderTests {
    private func makeDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("oolong-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func write(_ json: String, to dir: URL) throws {
        try json.write(to: dir.appendingPathComponent("ccbar-ratelimits.json"),
                       atomically: true, encoding: .utf8)
    }

    @Test func readsIntegerPercentages() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try write(#"{"five_hour":{"used_percentage":26,"resets_at":1780986000},"seven_day":{"used_percentage":30,"resets_at":1781067600}}"#, to: dir)

        let info = RateLimitProvider(claudeDir: dir).read()
        #expect(info?.fiveHour?.usedPercentage == 26)
        #expect(info?.sevenDay?.usedPercentage == 30)
        #expect(info?.fiveHour?.resetsAt == Date(timeIntervalSince1970: 1_780_986_000))
    }

    // 回归：Claude Code 给的 used_percentage 可能是浮点(28.000000000000004)，Int 解码会整体失败
    @Test func readsFloatPercentages() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try write(#"{"five_hour":{"used_percentage":28.000000000000004,"resets_at":1780986000},"seven_day":{"used_percentage":30.5,"resets_at":1781067600}}"#, to: dir)

        let info = RateLimitProvider(claudeDir: dir).read()
        #expect(info?.fiveHour?.usedPercentage == 28)
        #expect(info?.sevenDay?.usedPercentage == 31)
    }

    @Test func missingSevenDayStillReturnsFiveHour() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try write(#"{"five_hour":{"used_percentage":10,"resets_at":1780986000}}"#, to: dir)

        let info = RateLimitProvider(claudeDir: dir).read()
        #expect(info?.fiveHour?.usedPercentage == 10)
        #expect(info?.sevenDay == nil)
    }

    @Test func missingFileReturnsNil() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(RateLimitProvider(claudeDir: dir).read() == nil)
    }

    @Test func corruptJSONReturnsNil() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try write("not json at all", to: dir)
        #expect(RateLimitProvider(claudeDir: dir).read() == nil)
    }

    @Test func emptyObjectReturnsNil() throws {
        let dir = try makeDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try write("{}", to: dir)
        #expect(RateLimitProvider(claudeDir: dir).read() == nil)
    }
}

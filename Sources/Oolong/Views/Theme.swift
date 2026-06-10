import SwiftUI

/// 仿 Claude.ai 配色：暖米白底 + 陶土橙强调 + 暖近黑文字
enum Theme {
    static let bg            = Color(red: 0.949, green: 0.941, blue: 0.914)  // 暖米白 #F2F0E9
    static let card          = Color(red: 0.992, green: 0.988, blue: 0.980)  // 近白暖 #FDFCFA
    static let accent        = Color(red: 0.851, green: 0.467, blue: 0.341)  // 陶土橙 #D97757
    static let text          = Color(red: 0.122, green: 0.118, blue: 0.110)  // 暖近黑
    static let textSecondary = Color(red: 0.451, green: 0.443, blue: 0.420)  // 暖灰
    static let border        = Color(red: 0.890, green: 0.882, blue: 0.855)  // 浅暖边框
    static let track         = Color(red: 0.875, green: 0.863, blue: 0.827)  // 进度条底槽
    static let danger        = Color(red: 0.776, green: 0.318, blue: 0.251)  // 警示红(暖)
}

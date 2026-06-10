import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, zh
    var id: String { rawValue }
}

/// 轻量本地化：每处调用同时给英文/中文，按当前语言返回。
/// 切换走 AppModel.language(@Published) 触发重渲染；I18n.isZH 是渲染时读的缓存。
enum I18n {
    private static let key = "appLanguage"
    static var isZH: Bool = resolve(stored)

    static func t(_ en: String, _ zh: String) -> String { isZH ? zh : en }

    static var stored: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system
    }

    static func store(_ l: AppLanguage) {
        UserDefaults.standard.set(l.rawValue, forKey: key)
        isZH = resolve(l)
    }

    static func resolve(_ l: AppLanguage) -> Bool {
        switch l {
        case .zh: return true
        case .en: return false
        case .system: return (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("zh")
        }
    }
}

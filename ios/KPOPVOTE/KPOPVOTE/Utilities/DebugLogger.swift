import Foundation

/// デバッグ用ログ出力
/// リリースビルドでは何も出力しない
#if DEBUG
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
}
#else
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // リリースビルドでは何も出力しない
}
#endif

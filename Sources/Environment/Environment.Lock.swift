internal import Synchronization

extension Environment {

    internal static let lock = Mutex<Void>(())
}

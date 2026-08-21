public import Environment_Core

extension Environment.Snapshot {

    public static func current() -> Self {
        Self(Environment.read.all())
    }

    public static func effective() -> Self {
        Environment.task.effective()
    }
}

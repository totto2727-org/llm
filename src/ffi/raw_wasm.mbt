///|
/// Wasm stub: run shell command (not supported).
fn run_shell(_command : String, _timeout_ms : Int32) -> String {
  abort("run_shell is not supported on wasm target")
}

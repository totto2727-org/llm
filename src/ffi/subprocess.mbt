///|
/// Execute a command synchronously and return stdout.
pub fn exec_sync(command : String, timeout_ms : Int32) -> String {
  run_shell(command, timeout_ms)
}

///|
/// Run a command without blocking the scheduler, then deliver its stdout lines.
pub async fn exec_stream(
  command : String,
  args : Array[String],
  on_line : (String) -> Unit,
  on_done : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  let (code, stdout, stderr) = exec_async(command, args) catch {
    error => {
      on_error(@debug.to_string(error))
      return
    }
  }
  if code != 0 {
    on_error("exit code \{code}: \{stderr}")
    return
  }
  for line in stdout.split("\n") {
    if !line.trim(chars=" \t\r\n").is_empty() {
      on_line(line.to_owned())
    }
  }
  on_done()
}

///|
/// JS primitive: run a shell command, return stdout.
/// Returns "ERROR: ..." on failure.
fn run_shell(command : String, timeout_ms : Int32) -> String {
  js_run_shell(command, timeout_ms)
}

///|
extern "js" fn js_run_shell(command : String, timeout_ms : Int32) -> String =
  #|(command, timeoutMs) => {
  #|  try {
  #|    const { execSync } = require('child_process');
  #|    return execSync(command, { timeout: timeoutMs, encoding: 'utf-8' });
  #|  } catch (e) {
  #|    return 'ERROR: ' + (e.message || String(e));
  #|  }
  #|}

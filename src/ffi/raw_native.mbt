///|
#borrow(command)
extern "C" fn llm_popen_ffi(command : Bytes) -> String = "llm_popen_ffi"

///|
fn run_shell(command : String, _timeout_ms : Int32) -> String {
  llm_popen_ffi(mbt_string_to_utf8_bytes(command))
}

///|
#external
pub type JsValue

///|
pub fn[A, B] identity(a : A) -> B = "%identity"

///|
#external
pub type Promise[T]

///|
pub fn[T] Promise::to_any(self : Promise[T]) -> JsValue = "%identity"

///|
pub fn[T] Promise::from_async(run : async () -> T) -> Promise[T] {
  identity(@js_async.Promise::from_async(run))
}

///|
pub async fn[T] Promise::wait(self : Promise[T]) -> T {
  let promise : @js_async.Promise[T] = identity(self)
  promise.wait()
}

///|
pub async fn[T, E : Error] async_suspend(
  f : ((T) -> Unit, (E) -> Unit) -> Unit,
) -> T raise E = "%async.suspend"

///|
pub fn run_async(f : async () -> Unit noraise) -> Unit = "%async.run"

///|
/// Fetch text via the same standard async transport as the MoonBit APIs.
pub fn fetch_text_async(
  url : String,
  http_method : String,
  headers_json : String,
  body : String,
  timeout_sec : Int32,
) -> Promise[String] {
  Promise::from_async(async fn() {
    let (status, text) = fetch_async(
      url, http_method, headers_json, body, timeout_sec,
    ) catch {
      error => return "ERROR: " + @debug.to_string(error)
    }
    if status < 200 || status >= 300 {
      "ERROR: HTTP \{status}: \{text}"
    } else {
      text
    }
  })
}

///|
pub async fn[T] with_timeout(seconds : Int32, run : async () -> T) -> T {
  if seconds <= 0 {
    run()
  } else {
    @async.with_timeout(@cmp.minimum(seconds, 2147483) * 1000, run)
  }
}

///|
pub suberror UnexpectedStatus {
  UnexpectedStatus(Int32)
}

///|
pub async fn post(
  url : String,
  headers : @http.Headers,
  body : String,
  timeout_sec : Int32,
  on_data : (String) -> Unit,
) -> Unit {
  with_timeout(timeout_sec, async fn() {
    let client = @http.post_stream(url, headers~)
    defer client.close()
    client.write(body)
    let response = client.end_request()
    guard response.code >= 200 && response.code < 300 else {
      raise UnexpectedStatus(response.code)
    }
    let data : Array[String] = []
    while client.read_until("\n") is Some(line) {
      let line = line.trim_end(chars="\r").to_owned()
      if line.is_empty() {
        if !data.is_empty() {
          let frame = data.join("\n")
          if frame == "[DONE]" {
            return
          }
          on_data(frame)
          data.clear()
        }
      } else if line == "data" || line.has_prefix("data:") {
        let value = if line == "data" { "" } else { line[5:].to_owned() }
        data.push(
          if value.has_prefix(" ") {
            value[1:].to_owned()
          } else {
            value
          },
        )
      }
    }
  })
}

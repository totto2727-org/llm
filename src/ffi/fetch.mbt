///|
priv suberror HttpTransportError {
  InvalidHeaders
  UnexpectedStatus(Int32)
  UnsupportedMethod(String)
}

///|
fn http_headers(
  json : String,
) -> Map[@http.CaseInsensitiveString, String] raise {
  guard @json.parse(json) is Object(entries) else { raise InvalidHeaders }
  let headers : Map[@http.CaseInsensitiveString, String] = Map([])
  for name, value in entries {
    headers[@http.CaseInsensitiveString(name)] = match value {
      String(value) => value
      _ => value.stringify()
    }
  }
  headers
}

///|
async fn[T] within_http_timeout(timeout_sec : Int32, run : async () -> T) -> T {
  if timeout_sec <= 0 {
    run()
  } else {
    @async.with_timeout(@cmp.minimum(timeout_sec, 2147483) * 1000, run)
  }
}

///|
/// Read SSE data frames incrementally. Comments and non-data fields are ignored.
async fn read_sse(client : @http.Client, on_data : (String) -> Unit) -> Unit {
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
}

///|
/// POST an SSE request and deliver each complete data frame before reading the next one.
pub async fn fetch_sse(
  url : String,
  headers_json : String,
  body : String,
  timeout_sec : Int32,
  on_line : (String) -> Unit,
  on_error : (String) -> Unit,
  on_done : () -> Unit,
) -> Unit {
  within_http_timeout(timeout_sec, async fn() {
    let client = @http.post_stream(url, headers=http_headers(headers_json))
    defer client.close()
    client.write(body)
    let response = client.end_request()
    if response.code < 200 || response.code >= 300 {
      raise UnexpectedStatus(response.code)
    }
    read_sse(client, on_line)
  }) catch {
    UnexpectedStatus(code) => {
      on_error("HTTP \{code}")
      return
    }
    error => {
      on_error(@debug.to_string(error))
      return
    }
  }
  on_done()
}

///|
/// Perform an async HTTP request with a deadline covering headers and body.
pub async fn fetch_async(
  url : String,
  http_method : String,
  headers_json : String,
  body : String,
  timeout_sec : Int32,
) -> (Int32, String) {
  within_http_timeout(timeout_sec, async fn() {
    let headers = http_headers(headers_json)
    let (response, content) = match http_method {
      "GET" => @http.get(url, headers~)
      "POST" => @http.post(url, body, headers~)
      "PUT" => @http.put(url, body, headers~)
      _ => raise UnsupportedMethod(http_method)
    }
    (response.code, content.text())
  })
}

///|
/// Get an environment variable value. Returns empty string if not found.
pub fn get_env(name : String) -> String {
  @x_sys.get_env_var(name).unwrap_or("")
}

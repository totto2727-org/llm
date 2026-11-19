///|
async fn main {
  let url = @ffi.get_env("LLM_TEST_URL")
  let openai = @openai.OpenAIProvider::new_compat(
    url,
    "fixture",
    api_key="test",
    timeout_sec=5,
  )
  @async.with_task_group() <| group => {
    let received = @async.Semaphore::Semaphore(1, initial_value=0)
    let events : Array[String] = []
    let stream = group.spawn(async fn() {
      @llm.BoxedProvider::new(openai).stream(
        [@llm.Message::user("日本語")],
        [],
        {
          on_event: event => {
            match event {
              @llm.TextDelta(text) => {
                events.push(text)
                if events.length() == 1 {
                  received.release()
                }
              }
              @llm.MessageEnd(..) => events.push("end")
              @llm.Error(message) => events.push("error: " + message)
              _ => ()
            }
          },
        },
      )
    })
    // The server only sends the rest after the first callback runs.
    @async.with_timeout(3000, async fn() { received.acquire() })
    let (response, _) = @transport.get(url + "/continue")
    assert_eq(response.code, 204)
    stream.wait()
    assert_eq(events, ["first", "日本語", "end"])
  }
  let anthropic = @anthropic.AnthropicProvider::new(
    "test",
    model="fixture",
    base_url=url,
    timeout_sec=5,
  )
  assert_eq(
    @llm.collect_text(anthropic, [@llm.Message::user("hello")]),
    "anthropic",
  )
  let errors : Array[String] = []
  let events : Array[String] = []
  for path in ["/failure", "/timeout"] {
    @ffi.fetch_sse(
      url + path,
      "{}",
      "{}",
      1,
      event => events.push(event),
      error => errors.push(error),
      fn() { events.push("unexpected completion") },
    )
  }
  assert_eq(errors.length(), 2)
  assert_true(errors[0].contains("503"))
  assert_eq(events, [])
  @async.with_task_group() <| group => {
    let received = @async.Semaphore::Semaphore(1, initial_value=0)
    let task = group.spawn(
      async fn() {
        @ffi.fetch_sse(
          url + "/cancel",
          "{}",
          "{}",
          5,
          fn(_) { received.release() },
          error => errors.push(error),
          fn() { events.push("unexpected completion") },
        )
      },
      allow_failure=true,
    )
    @async.with_timeout(3000, async fn() { received.acquire() })
    task.cancel()
    let cancelled = try {
      task.wait()
      false
    } catch {
      @async.WaitedTaskAlreadyCancelled => true
      error => raise error
    }
    assert_true(cancelled)
    assert_eq(errors.length(), 2)
    assert_eq(events, [])
  }
  println("HTTP_SSE_OK")
}

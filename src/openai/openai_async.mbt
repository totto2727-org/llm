///|
/// JavaScript Promise adapter for the portable, non-streaming completion API.
pub fn OpenAIProvider::collect_text_async(
  self : OpenAIProvider,
  messages : Array[@llm.Message],
  tools~ : Array[@llm.ToolDef] = [],
) -> @ffi.Promise[String] {
  @ffi.Promise::from_async(async fn() { self.collect_text(messages, tools~) })
}

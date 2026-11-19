///|
fn parse_openai_collect_text_response(response_text : String) -> String {
  let response = @json.parse(response_text) catch { _ => return "" }
  let choices = match @llm.json_get_array(response, "choices") {
    Some(value) => value
    None => return ""
  }
  if choices.is_empty() {
    return ""
  }
  let message = match @llm.json_get_object(choices[0], "message") {
    Some(value) => value
    None => return ""
  }
  @llm.json_get_string(message, "content").unwrap_or("")
}

///|
/// Cross-target async non-streaming completion backed by standard async HTTP.
/// Returns an empty string for transport, HTTP, or response parsing errors.
pub async fn OpenAIProvider::collect_text(
  self : OpenAIProvider,
  messages : Array[@llm.Message],
  tools~ : Array[@llm.ToolDef] = [],
) -> String {
  let path = match self.endpoint {
    Cloudflare(..) => "/run/" + self.config.model
    _ => "/v1/chat/completions"
  }
  let url = self.config.base_url + path
  let headers = build_openai_headers(self.config.api_key, self.endpoint)
  let body = build_openai_body(
    self.config.model,
    self.config.max_tokens,
    self.config.system_prompt,
    messages,
    tools,
    stream=false,
  )
  let (response, content) = @sse.with_timeout(self.config.timeout_sec, async fn() {
    @http.post(url, body.stringify(), headers~)
  }) catch {
    _ => return ""
  }
  if response.code < 200 || response.code >= 300 {
    return ""
  }
  parse_openai_collect_text_response(content.text())
}

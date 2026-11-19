///|
fn provider_json_get_field(obj : Json, key : String) -> Json? {
  match obj {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn provider_json_get_string(obj : Json, key : String) -> String? {
  match provider_json_get_field(obj, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
priv struct CaptureProvider {
  mut received_messages : Array[@llm.Message]
  mut received_tools : Array[@llm.ToolDef]
  emit_events : Array[@llm.StreamEvent]
}

///|
impl @llm.Provider for CaptureProvider with fn stream(
  self,
  messages,
  tools,
  handler,
) {
  self.received_messages = messages
  self.received_tools = tools
  for event in self.emit_events {
    (handler.on_event)(event)
  }
}

///|
impl @llm.Provider for CaptureProvider with fn name(_self) -> String {
  "capture"
}

///|
test "llm_chat_provider converts messages and tools" {
  let provider : CaptureProvider = {
    received_messages: [],
    received_tools: [],
    emit_events: [
      @llm.MessageStart,
      @llm.TextDelta("answer"),
      @llm.MessageEnd(finish_reason=@llm.Stop, usage=None),
    ],
  }
  let adapter = llm_chat_provider(provider)
  let messages : Array[Json] = [
    { "role": "system", "content": "SYS" },
    { "role": "user", "content": "U" },
    {
      "role": "assistant",
      "content": "",
      "tool_calls": Json::array([
        {
          "id": "c1",
          "type": "function",
          "function": { "name": "echo", "arguments": "{\"text\":\"hi\"}" },
        },
      ]),
    },
    {
      "role": "tool",
      "tool_call_id": "c1",
      "name": "echo",
      "content": "ECHO:hi",
    },
  ]
  let tools : Array[Json] = [
    {
      "type": "function",
      "function": {
        "name": "echo",
        "description": "echo text",
        "parameters": {
          "type": "object",
          "properties": { "text": { "type": "string" } },
        },
      },
    },
  ]
  let response = (adapter : &ChatProvider).chat(
    messages, tools, "ignored-model",
  )
  assert_eq(response.content, "answer")
  assert_eq(provider.received_messages.length(), 4)
  assert_eq(provider.received_tools.length(), 1)
  let assistant_json = provider.received_messages[2].to_openai_json()
  assert_true(!(provider_json_get_field(assistant_json, "tool_calls") is None))
  let tool_json = provider.received_messages[3].to_openai_json()
  @debug.debug_inspect(
    provider_json_get_string(tool_json, "role"),
    content="Some(\"tool\")",
  )
  @debug.debug_inspect(
    provider_json_get_string(tool_json, "tool_call_id"),
    content="Some(\"c1\")",
  )
}

///|
test "llm_chat_provider maps tool calls from llm collect" {
  let provider : CaptureProvider = {
    received_messages: [],
    received_tools: [],
    emit_events: [
      @llm.MessageStart,
      @llm.ToolCallEnd(id="call_1", name="read_file", input={ "path": "a.txt" }),
      @llm.MessageEnd(finish_reason=@llm.ToolUse, usage=None),
    ],
  }
  let adapter = llm_chat_provider(provider)
  let response = (adapter : &ChatProvider).chat([], [], "m")
  assert_eq(response.tool_calls.length(), 1)
  assert_eq(response.tool_calls[0].id, "call_1")
  assert_eq(response.tool_calls[0].name, "read_file")
}

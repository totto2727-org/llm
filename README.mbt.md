# MoonBit LLM client

`totto2727/llm` is a compatibility fork of [`mizchi/llm`](https://github.com/mizchi/llm) for current MoonBit releases.
It provides shared request and response types, streaming events, and provider adapters.

After the version is published on [Mooncakes](https://mooncakes.io/docs/totto2727/llm), add `totto2727/llm@0.3.3` to `moon.mod` and import `totto2727/llm` in `moon.pkg`.
The default package alias remains `@llm`.

## Runtimes

OpenAI-compatible and Anthropic providers use `moonbitlang/async/http` to stream responses on JavaScript, native, and Wasm1.
For JavaScript, use Node.js with Fetch or a browser with a CORS-compatible endpoint.
For Wasm1, use a host that provides MoonBit async socket support, such as `moonrun`.
Wasm GC is not supported by this version of the async HTTP library.
Claude Code requires a host that can launch the installed `claude` executable and is not available in browsers.

`Provider::stream`, `collect`, `collect_text`, and the agent loops are async and must be called from an async context.
Provider trait implementations still use `impl Provider for Type with fn stream`; the trait supplies the async effect.

See [upstream differences](docs/upstream-differences.md) for the upstream revision, compatibility changes, and release procedure.

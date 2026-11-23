# Upstream differences

This fork is based on [`mizchi/llm@8ff08f81f8ecaa5b1b22c94b16a121d151455efa`](https://github.com/mizchi/llm/commit/8ff08f81f8ecaa5b1b22c94b16a121d151455efa).

| Difference | Affected files | Operational impact |
| --- | --- | --- |
| Adapt the dependency versions, trait calls, derives, and tests to the MoonBit SDK selected in `flake.lock`. | `moon.mod`, `src/` | The fork compiles with the current SDK without relying on implicit trait lookup. The provider protocol and JSON shapes do not intentionally change. |
| Publish separately from upstream under `totto2727/llm` and align the manifest's license with the inherited Apache-2.0 `LICENSE`. | `moon.mod`, `src/**/moon.pkg`, `.github/workflows/publish.yml` | The template's shared Mooncakes workflow publishes on pushes to `main`. This does not replace or publish into the `mizchi` namespace. |
| Replace the FFI package and JavaScript Promise compatibility API with standard async HTTP. Await Claude Code subprocesses instead of blocking the scheduler. | `src/internal/sse/`, `src/openai/`, `src/anthropic/`, `src/claude_code/`, and provider and agent interfaces | `Provider::stream`, collection, and agent loops are async. The shared SSE decoder reads frames incrementally, with deadlines and cancellation. Claude Code uses `mizchi/x/process` on Node.js, native, and Wasm1 and still buffers CLI output until exit. |
| Use the [MoonBit CI template](https://github.com/totto2727-org/template-moonbit-simple/blob/main/.github/workflows/ci.yml). | `.github/workflows/ci.yml`, `.github/workflows/copilot-setup-steps.yml`, `flake.nix`, `flake.lock` | The shared actions use the hook-free Nix `ci` shell and the module's default JavaScript target. Native and Wasm1 verification is local only. |

## Release

The [Publish workflow](../.github/workflows/publish.yml) runs on pushes to `main` and uses the repository's GitHub Actions access to `MOONCAKES_TOKEN`.
Verify the exact version is available in the Mooncakes index and that the downloaded archive matches its checksum before merging a dependent PR.

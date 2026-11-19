# Upstream differences

This fork is based on [`mizchi/llm@8ff08f81f8ecaa5b1b22c94b16a121d151455efa`](https://github.com/mizchi/llm/commit/8ff08f81f8ecaa5b1b22c94b16a121d151455efa).

| Difference | Affected files | Operational impact |
| --- | --- | --- |
| Adapt the dependency versions, trait calls, derives, and tests to MoonBit `20261117`. | `moon.mod`, `src/` | The fork compiles with the current SDK without relying on implicit trait lookup. The provider protocol and JSON shapes do not intentionally change. |
| Publish separately from upstream under `totto2727/llm` and align the manifest's license with the inherited Apache-2.0 `LICENSE`. | `moon.mod`, `src/**/moon.pkg` | Consumers must select the fork explicitly. This does not replace or publish into the `mizchi` namespace. |
| Use standard async HTTP for streaming and non-streaming OpenAI-compatible and Anthropic calls. Await Claude Code subprocesses instead of blocking the scheduler. | `src/ffi/`, `src/openai/`, `src/anthropic/`, `src/claude_code/`, and provider and agent interfaces | `Provider::stream`, collection, and agent loops are async. HTTP streaming delivers complete SSE frames incrementally, with deadlines and cancellation. The subprocess adapter still buffers CLI output until exit. |
| Use the [MoonBit CI template](https://github.com/totto2727-org/template-moonbit-simple/blob/main/.github/workflows/ci.yml). | `.github/workflows/ci.yml`, `.github/workflows/copilot-setup-steps.yml`, `flake.nix`, `flake.lock` | The shared actions use the hook-free Nix `ci` shell and the module's default JavaScript target. Native and Wasm1 verification is local only. |

## Release

After the compatibility PR is merged, an authorized `totto2727` Mooncakes maintainer can run `moon package` on the reviewed commit and publish it with `moon publish`.
Verify the exact version is available in the Mooncakes index and that the downloaded archive matches its checksum before merging a dependent PR.

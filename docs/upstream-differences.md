# Upstream differences

This fork is based on [`mizchi/llm@8ff08f81f8ecaa5b1b22c94b16a121d151455efa`](https://github.com/mizchi/llm/commit/8ff08f81f8ecaa5b1b22c94b16a121d151455efa).

| Difference | Affected files | Operational impact |
| --- | --- | --- |
| Adapt the dependency versions, trait calls, derives, and tests to MoonBit `20261117`. | `moon.mod`, `src/` | The fork compiles with the current SDK without relying on implicit trait lookup. The provider protocol and JSON shapes do not intentionally change. |
| Publish separately from upstream under `totto2727/llm` and align the manifest's license with the inherited Apache-2.0 `LICENSE`. | `moon.mod`, `src/**/moon.pkg` | Consumers must select the fork explicitly. This does not replace or publish into the `mizchi` namespace. |
| Check the native target as well as JavaScript. | `.github/workflows/ci.yml` | The existing `test` check covers both targets and retains the upstream installation procedure. |

## Release

After the compatibility PR is merged, an authorized `totto2727` Mooncakes maintainer can run `moon package` on the reviewed commit and publish it with `moon publish`.
Verify the exact version is available in the Mooncakes index and that the downloaded archive matches its checksum before merging a dependent PR.

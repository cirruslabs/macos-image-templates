# Tart Metal capabilities

This is a vendored adaptation of the minimal [Cua/Lume Metal capability shim](https://github.com/trycua/cua/tree/3c1acf27748c3e0f8ff71cd0c9ab072b1e160997/libs/lume/metal-capability-shim)
at revision `3c1acf27748c3e0f8ff71cd0c9ab072b1e160997`. The full shim source and
Metal capability probe are copied here. The source's `Lume` identifiers,
diagnostics, and `LUME_METAL_*` settings are renamed to `Tart` and `TART_METAL_*`.
The original Cua copyright and [MIT license](LICENSE) are retained. The upstream
source SHA-256 before renaming is
`e1371b1e579bca895e6b3a2b581b9f328203d9786bf809912a4a5d1672010cce`.

The shim changes only Apple-family capability answers and selected memory
limits. It does not advertise additional Common, Mac, or Metal families. It
uses private, version-sensitive behavior; reported capabilities are not a
guarantee that every corresponding GPU operation is supported.

Configuration is read once, when each process loads the library:

| Variable | Behavior |
| --- | --- |
| `TART_METAL_APPLE_FAMILY_MAX` | Required Apple-family ceiling, from 1001 through 1999. Missing, zero, or invalid values disable the shim. |
| `TART_METAL_MAX_THREADGROUP_MEMORY` | Memory floor in bytes; defaults to 65536. |
| `TART_METAL_RECOMMENDED_WORKING_SET_SIZE` | Optional working-set floor in bytes; unchanged when unset. |

The old `LUME_METAL_*` names are not recognized. Base images install the library
without enabling it for the guest agent or other processes. See the repository's
[Metal capabilities instructions](../../README.md#metal-capabilities) for
explicit per-command activation and host setup.

From the repository root, run `bash scripts/test-tart-metal-capabilities.sh` to
build and test without installing anything on the host. The installer accepts
`DESTDIR` for staging and `TART_METAL_SOURCE_DIR` for Packer's uploaded sources.

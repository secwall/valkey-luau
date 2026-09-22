# valkey-luau

A [Luau](https://luau.org) scripting engine module for Valkey, providing `EVAL`,
`EVALSHA`, `SCRIPT` and `FUNCTION` backed by an embedded Luau VM.

## Build

```bash
git submodule update --init --recursive
./build.sh
```

Module output: `build/libvalkeyluau.so`

## Tests

```bash
./build.sh --with-tests
./tests/run-valkey-tests.sh
./tests/run-valkey-tests.sh --single unit/scripting
```

## Loading

```
valkey-server --loadmodule build/libvalkeyluau.so
```

Or in `valkey.conf`:

```
loadmodule build/libvalkeyluau.so
```

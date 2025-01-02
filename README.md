# AVR Toolchain with libstdc++ Support

## Using in PlatformIO

This toolchain comes with a [companion platform](https://github.com/modern-avr/platform), so the easiest way to use it is as follows:

```ini
[env]
platform = https://github.com/modern-avr/platform.git
board = ...
```

That's it!

## What Does It Change?

Aside from providing a newer compiler, it makes a few changes to the build flags:

### For C++:
- Replaces `-std=c++11` with `-std=gnu++26`.
- Removes `-fpermissible` to encourage better coding practices.
- Adds `-Wno-volatile` because Arduino framework uses `volatile` in a now deprecated way.

### For C:
- Replaces `-std=c11` with `-std=gnu23`.

You can re-enable or disable any flags using `build_flags` and `build_unflags`, as usual.

## Supported Platforms

Currently, the toolchain has been built for:
- `linux_x86_64`
- `windows_amd64`

Pull requests for additional platforms are welcome.

## Building from Source

### Prerequisites:

- Docker
- GNU Make
- Bash

| Toolchain     | Space   | Time    |
|---------------|---------|---------|
| `windows_amd64` | 72 GiB  | 125 min |
| `linux_x86_64`  | 52 GiB  | 82 min  |

The build times were measured on an AMD Ryzen 9 7845HX 18-core VM with 32 GB RAM. If you build both toolchains, you'll save around 2.5 GiB due to base image overlap.

Space usage is approximate, as accurate measurement is difficult due to cleanups. Having 100 GiB of free space should suffice.

Currently, only building on Linux is supported. If you can make this run on Windows or macOS, please submit a pull request.

### Configuring (Optional)

Run:

```bash
make menuconfig
```

Note: Building Bison and Mold is broken on Windows, so they are disabled. Building DTC for Windows requires patches (included).

Please do not change anything related to paths or filenames, as the packaging scripts will not recognize new values.

### Building

To build the `linux_x86_64` toolchain:

```bash
make linux_x86_64
```

To build the `windows_amd64` toolchain:

```bash
make windows_amd64
```

To build all toolchains (e.g., both):

```bash
make all
```

### Cleaning Up

To remove just-built toolchains:

```bash
make clean
```

To also remove the build cache:

```bash
make distclean
```

## Troubleshooting

### Build has not completed

Simply run the build command again.

### Build has completed with an error

The most common reasons for failure are:
1. Insufficient disk space.
2. Insufficient RAM.

To mitigate this, run:

```bash
make menuconfig
```

and reduce the number of concurrent jobs.

When a build fails, `build.log` (if available) is automatically copied to the repository root, overwriting any previous version.

To resume building, rerun the build command. It will pick up from the last successful step automatically.

To resume building from a specific step, run:

```bash
make linux_x86_64 RESUME=linker
```

Replace the target OS and build step accordingly.

---

Copyright © 2024 toriningen <toriningen.me@gmail.com>

This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See the [COPYING](./COPYING) file for more details.


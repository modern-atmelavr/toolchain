#!/usr/bin/env python3

import re


def read_versions():
    rx_version = re.compile(r'^CT_(\w+)_VERSION="([+.\w]+)"$')

    versions = {}

    with open('config.in', 'r') as fp:
        for line in fp:
            line = line.strip()
            rxm = rx_version.match(line)
            if not rxm:
                continue

            name, version = rxm.groups()
            name = name.lower()
            if name == 'config':
                continue

            versions[name] = version

    return versions


def print_versions(versions):
    order = [
        'gcc',
        'gdb',
        'binutils',
        'avr_libc',
        None,
        'autoconf',
        'automake',
        'libtool',
        'm4',
        'make',
        None,
        'gmp',
        'mpc',
        'mpfr',
        'isl',
        'cloog',
        None,
        'dtc',
        'expat',
        'ncurses',
        'zlib',
        'zstd',
    ]

    for name in order:
        if name is None:
            print()
        else:
            print(f'{name}: {versions[name]}')


def main():
    versions = read_versions()
    print('The toolchain has been built with the following package versions:')
    print()
    print('```')
    print_versions(versions)
    print('```')


if __name__ == '__main__':
    main()

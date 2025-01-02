#!/usr/bin/env python3

import sys
from pathlib import Path


def parse_patch(lines):
    patch = {}

    for line in lines:
        line = line.rstrip('\n')
        stripped = line.split('#', 1)[0].strip()
        if not stripped:
            continue

        op, payload = line.split(' ', 1)
        if op == 'set':
            key, value = payload.split('=', 1)
            patch[key] = value
        elif op == 'unset':
            key = payload
            patch[key] = None
        else:
            raise ValueError(f'unknown op: {line!r}')

    return patch


def parse_config(lines):
    config = {}
    for line in lines:
        line = line.rstrip('\n')

        if line.startswith('#'):
            continue

        if not line:
            continue

        key, value = line.split('=', 1)
        config[key] = value

    return config


def write_config(config):
    for key, value in config.items():
        if value is None:
            continue

        yield f'{key}={value}\n'


def main(config_file, patch_file, output_file):
    config_file = Path(config_file)
    patch_file = Path(patch_file)
    output_file = Path(output_file)

    with patch_file.open('r', encoding='utf8') as fp:
        patch = parse_patch(list(fp))

    with config_file.open('r', encoding='utf8') as fp:
        config = parse_config(list(fp))

    config.update(patch)

    with output_file.open('w', encoding='utf8') as fp:
        for line in write_config(config):
            fp.write(line)


if __name__ == '__main__':
    main(*sys.argv[1:])

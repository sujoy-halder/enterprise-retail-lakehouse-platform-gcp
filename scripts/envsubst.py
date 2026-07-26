#!/usr/bin/env python3
import os
import re
import sys


pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")


def replace(match: re.Match[str]) -> str:
    name = match.group(1)
    return os.environ.get(name, match.group(0))


sys.stdout.write(pattern.sub(replace, sys.stdin.read()))


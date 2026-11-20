"""Extract only regular files from the published Lean source archive."""

import shutil
import sys
import tarfile
from pathlib import Path, PurePosixPath

destination = Path(sys.argv[1])
destination.mkdir(parents=True, exist_ok=True)
if (destination / "lean").exists():
    raise SystemExit("destination already contains lean")

with tarfile.open(fileobj=sys.stdin.buffer, mode="r|gz") as archive:
    for member in archive:
        path = PurePosixPath(member.name)
        if path.parts[:1] != ("lean",) or ".." in path.parts or not member.isfile():
            raise ValueError(f"unexpected archive entry: {member.name!r}")
        if any(part.casefold() == ".git" for part in path.parts):
            raise ValueError(f"unexpected Git metadata: {member.name!r}")
        target = destination.joinpath(*path.parts)
        if not target.parent.is_dir():
            target.parent.mkdir(parents=True, exist_ok=True)
        with archive.extractfile(member) as source, target.open("xb") as output:
            shutil.copyfileobj(source, output)

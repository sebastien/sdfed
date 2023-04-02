from typing import Optional, Any
from io import BytesIO
import struct
import numpy as np
from base64 import b64encode
from sdf.mesh import generate
from sdf.d3 import SDF3

# NOTE: This is the same as sdf.stl, execpt it writes to the buffer
def stl(output: BytesIO, shape: SDF3, samples: int = 16):
    points = generate(shape, samples=2**samples)
    n = len(points) // 3

    points = np.array(points, dtype="float32").reshape((-1, 3, 3))
    normals = np.cross(points[:, 1] - points[:, 0], points[:, 2] - points[:, 0])
    normals /= np.linalg.norm(normals, axis=1).reshape((-1, 1))

    dtype = np.dtype(
        [
            ("normal", ("<f", 3)),
            ("points", ("<f", (3, 3))),
            ("attr", "<H"),
        ]
    )

    a = np.zeros(n, dtype=dtype)
    a["points"] = points
    a["normal"] = normals

    output.write(b"\x00" * 80)
    output.write(struct.pack("<I", n))
    output.write(a.tobytes())
    return output


def shape(code: str) -> Optional[SDF3]:
    glo: dict[str, Any] = {}
    loc: dict[str, Any] = {}
    exec("from sdf import *\n", glo, loc)
    exec(code, glo, loc)
    shape = loc.get("shape")
    shapes = [_ for _ in {_ for _ in loc.values() if isinstance(_, SDF3)}]
    if shape and isinstance(shape, SDF3):
        return shape
    elif shapes:
        return shapes[-1]
    else:
        return None


def mesh(shape: SDF3) -> str:
    buf = stl(BytesIO(), shape)
    buf.seek(0)
    return str(b64encode(buf.read()), "ascii")


def render(code: str) -> str:
    return stl(model(code))


if __name__ == "__main__":
    import os
    import sys
    from pymeshlab import MeshSet

    for p in sys.argv[1:]:
        with open(p, "rt") as f:
            print("---")
            s = shape(f.read())
            if s:
                with open(
                    name := f"{os.path.splitext(os.path.basename(p))[0]}.stl", "wb"
                ) as g:
                    print(f"Writing to {name}")
                    stl(g, s)
                m = MeshSet()
                m.load_new_mesh(name)
                m.save_current_mesh(name.replace(".stl", ".obj"))
# EOF

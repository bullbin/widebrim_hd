from os.path import join, basename, splitext
from typing import Optional
import ffmpeg

def mp4_to_ogv(path_mp4 : str, path_out : str, path_custom_ffmpeg : Optional[str] = None, quality : int = 7) -> bool:

    if path_custom_ffmpeg == None:
        path_custom_ffmpeg = "ffmpeg"

    path_out = join(path_out, splitext(basename(path_mp4))[0] + ".ogv")

    # TODO - Check if audio present, do not AN if so (but audio should never be there!)
    process = (ffmpeg
                .input(path_mp4)
                .output(path_out, format="ogv", vcodec="libtheora", an=None, loglevel="quiet", **{'qscale:v': quality})
                .run_async(cmd=path_custom_ffmpeg)
                )
    
    _ = process.communicate()

    return True
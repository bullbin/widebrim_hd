from math import ceil
from os import cpu_count
from os.path import exists, splitext
from subprocess import Popen
from time import sleep
from typing import List

import ffmpeg

from . import OneLinePrinter

max_thread_count    : int   = max(1, min(ceil(cpu_count() * 0.5), cpu_count() - 1))

def mp4_to_ogv_pool(paths_mp4 : List[str], command_ffmpeg : str = "ffmpeg", quality : int = 7) -> List[str]:

    pool : List[Popen] = []
    path_pool : List[str] = []

    paths_successful : List[str] = []

    printer = OneLinePrinter()
    printer.print("Converting cutscene videos...")

    ffmpeg_inputs = list(paths_mp4)
    while len(ffmpeg_inputs) > 0:
        for idx in range(len(pool) - 1, -1, -1):
            if not(pool[idx].poll() is None):
                if pool[idx].wait() == 0:
                    paths_successful.append(path_pool[idx])
                    printer.print("Converting videos, ~%d/%d" % (len(paths_successful), len(paths_mp4)))

                pool.pop(idx)
                path_pool.pop(idx)

        if len(pool) >= max_thread_count:
            sleep(0.01)
            continue
        else:
            path_input = ffmpeg_inputs.pop()
            path_output = splitext(path_input)[0] + ".ogv"

            if exists(path_output):
                paths_successful.append(path_input)
                continue

            process = (ffmpeg
                       .input(path_input)
                       .output(path_output, format="ogv", vcodec="libtheora", an=None, loglevel="quiet", **{'qscale:v': quality})
                       .run_async(cmd=command_ffmpeg)
                       )
            
            pool.append(process)
            path_pool.append(path_input)
    
    while len(pool) > 0:
        for idx in range(len(pool) - 1, -1, -1):
            if not(pool[idx].poll() is None):
                if pool[idx].wait() == 0:
                    paths_successful.append(path_pool[idx])
                    printer.print("Converting videos, ~%d/%d" % (len(paths_successful), len(paths_mp4)))

                pool.pop(idx)
                path_pool.pop(idx)
        sleep(0.01)
    
    printer.print("Converted videos, %d/%d!" % (len(paths_successful), len(paths_mp4)))
    print("")

    return paths_successful
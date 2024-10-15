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
    png_done : List[bool] = []

    paths_successful : List[str] = []

    printer = OneLinePrinter()
    printer.print("Converting cutscene videos...")

    def clean_pool():
        for idx in range(len(pool) - 1, -1, -1):
            if not(pool[idx].poll() is None):
                if pool[idx].wait() == 0:
                    # Godot has some limitations with video playback, LT2R holds the last frame which Godot cannot
                    #     do (and we can't find the last frame anyway because stream length is not implemented!)
                    # Reuse pool after video completed to convert the last frame out as a PNG for later.

                    # If PNG was done, we're actually done
                    if png_done[idx]:
                        paths_successful.append(path_pool[idx])
                        printer.print("Converting videos, ~%d/%d" % (len(paths_successful), len(paths_mp4)))
                        pool.pop(idx)
                        path_pool.pop(idx)
                        png_done.pop(idx)
                    else:
                        # Else, replace this process with one that converts the PNG and continue
                        path_ogv = splitext(path_pool[idx])[0] + ".ogv"
                        path_png = splitext(path_pool[idx])[0] + ".png"

                        png_done[idx] = True

                        if not(exists(path_png)):
                            process = (ffmpeg
                                       .input(path_ogv, sseof=-1)
                                       .output(path_png, an=None, loglevel="quiet", **{'update': 1})
                                       .run_async(cmd=command_ffmpeg)
                                       )

                            pool[idx] = process
                else:
                    # If conversion failed, remove from pool
                    pool.pop(idx)
                    path_pool.pop(idx)
                    png_done.pop(idx)

    ffmpeg_inputs = list(paths_mp4)
    while len(ffmpeg_inputs) > 0:
        clean_pool()

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
            png_done.append(False)
    
    while len(pool) > 0:
        clean_pool()
        sleep(0.01)
    
    printer.print("Converted videos, %d/%d!" % (len(paths_successful), len(paths_mp4)))
    print("")

    return paths_successful
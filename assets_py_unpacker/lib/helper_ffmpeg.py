from subprocess import DEVNULL, PIPE, Popen, call
from typing import List

def does_ffmpeg_support_features(path_executable : str, required_libs : List[str] = ["libx264", "libtheora", "libopus"]) -> bool:
    """Check if FFMPEG install at provided path supports the required features.

    Args:
        path_executable (str): Path (or command) to execute FFMPEG.
        required_libs (List[str], optional): Desired build flags for FFMPEG. Defaults to ["libx264", "libtheora", "libopus"].

    Returns:
        bool: True if FFMPEG is valid and was build with required libraries, False otherwise.
    """

    if call("%s -version" % path_executable, stderr=DEVNULL, stdout=DEVNULL, shell=True) != 0:
        return False
    
    proc = Popen(path_executable, shell=False, text=True, stdout=DEVNULL, stderr=PIPE)
    configurations : List[str] = []
    for line in proc.communicate()[1].splitlines():
        line = line.strip()
        if line.startswith("configuration: --"):
            configurations = [x[7:] for x in line.split(" --") if x.startswith("enable-")]
            break
    
    for library in required_libs:
        if library not in configurations:
            return False
    
    return True
from PyCriCodecs import *
from os.path import join, normpath, basename, splitext, dirname
from os import makedirs
from typing import Tuple, List, Dict, Optional, Union
from io import BytesIO
import ffmpeg
import subprocess

class DeferredACB(ACB):

    def __init__(self, filename : Union[str, bytearray], awb_add : Union[str, bytearray]) -> None:
        self.payload = UTF(filename).get_payload()
        self.awb_bytes = awb_add
        self.filename = filename
        self.acbparse(self.payload)
        
    def load_awb(self) -> None:
        if self.payload[0]['AwbFile'][1] == b'':
            awbObj = AWB(self.awb_bytes)
        else:
            awbObj = AWB(self.payload[0]['AwbFile'][1])
        self.awb = awbObj

def wav_to_ogg_ffmpeg(data_wav : bytearray, quality : int = 6, path_custom_ffmpeg : Optional[str] = None) -> Tuple[Optional[bytearray], bool, float]:

    if path_custom_ffmpeg == None:
        path_custom_ffmpeg = "ffmpeg"

    def wav_to_ogg(data_wav : bytearray) -> bytearray:
        pipe_hunger = BytesIO(data_wav)
        
        process = (ffmpeg
                   .input('pipe:')
                   .output('pipe:', format="ogg", acodec="libvorbis", loglevel="quiet", **{'qscale:a': quality})
                   .run_async(pipe_stdin=True, pipe_stdout=True, cmd=path_custom_ffmpeg)
                   )

        output, _ = process.communicate(input=pipe_hunger.getbuffer())
        return bytearray(output)

    if data_wav[:4] != b'RIFF':
        return (None, False, 0)
    
    if data_wav[8:16] != b'WAVEfmt ':
        return (None, False, 0)

    has_loop_block = data_wav[36:40] == b'smpl'

    if has_loop_block:
        offset_data = int.from_bytes(data_wav[0x10:0x14], byteorder='little') + int.from_bytes(data_wav[40:44], byteorder='little') + 20 + 8
        sampling_rate = int.from_bytes(data_wav[0x18:0x1c], byteorder='little')
        bytes_per_frame = int.from_bytes(data_wav[0x20:0x22], byteorder='little')

        count_loop = int.from_bytes(data_wav[0x48:0x4c], byteorder='little')
        if count_loop > 1:
            print("Unsupported!")
            return (wav_to_ogg(data_wav), False, 0)
        
        if count_loop == 0:
            return (wav_to_ogg(data_wav), False, 0)
        
        start = int.from_bytes(data_wav[0x58:0x5c], byteorder='little')
        end = int.from_bytes(data_wav[0x5c:0x60], byteorder='little')
        resolution = int.from_bytes(data_wav[0x60:0x64], byteorder='little')

        if resolution == 0:
            resolution = 1
        else:
            resolution = resolution / 100
        
        start *= resolution
        end *= resolution

        len_data = int.from_bytes(data_wav[offset_data + 4: offset_data + 8], byteorder='little')
        total_samples = int(len_data / bytes_per_frame)

        if total_samples > end and resolution != 1:
            print("Cannot cull samples!")
            return (wav_to_ogg(data_wav), False, 0)
        else:
            cull_offset = offset_data + 8 + (end * bytes_per_frame)
            data_wav = data_wav[:cull_offset]
            data_wav[4:8] = (cull_offset - 8).to_bytes(4, byteorder='little')
            data_wav[offset_data + 4: offset_data + 8] = (end * bytes_per_frame).to_bytes(4, byteorder='little')
        
        duration = total_samples / sampling_rate
        l_start = start / total_samples * duration

        return (wav_to_ogg(data_wav), True, l_start)
    
    return (wav_to_ogg(data_wav), False, 0)

def naive_decode_wav_from_acb(path_acb : Union[str, bytearray], path_out : str, force_remap : bool = False, auto_remap : bool = True, compress : bool = True, data_awb : Optional[bytearray] = None, path_custom_ffmpeg : Optional[str] = None) -> bool:
    """Extract samples from an ACB file with an attempt to preserve proper filenames.

    Files will be converted to either OGG or WAV with same filename (different extension). Compression quality for ACB is balanced to provide good quality at the same size as the original.

    Remapping support is experimental. While it does resolve a mapping from name to tracks that matches other software, sometimes tracks are not in the expected order, breaking everything. Use at your
    own risk.

    Compression requires ffmpeg. If ffmpeg is not installed correctly, compression will be disabled.

    Args:
        path_acb (Union[str, bytearray]): Path to ACB archive or raw bytes. If bytes are used, data_awb must be supplied.
        path_out (str): Path to output directory. If using bytes for ACB, add the export folder name to the output path.
        force_remap (bool, optional): Forces filename re-processing. Defaults to False.
        auto_remap (bool, optional): Automatically enables filename re-processing if extra track references are found in the file. Defaults to True.
        compress (bool, optional): Export as OGG instead of WAV. OGG has comparable space / quality to the original and requires extra metadata. WAV is large but embeds metadata. Defaults to True.
        data_awb (Optional[bytearray], optional): AWB file to store samples. Only required if path_acb is bytes; if the AWB is bundled and the ACB is binary, set as an empty byte string. Defaults to None.
        path_custom_ffmpeg (Optional[str], optional): Alternative path to FFMPEG executable. None to use system FFMPEG.

    Returns:
        bool: True if extraction was successful.
    """

    if path_custom_ffmpeg == None:
        test_ffmpeg_call = "ffmpeg"
    else:
        test_ffmpeg_call = path_custom_ffmpeg

    if subprocess.call("%s -version" % test_ffmpeg_call, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL, shell=True) != 0:
        compress = False

    if type(path_acb) == str:
        path_acb = normpath(path_acb)
        path_out = join(normpath(path_out), splitext(basename(path_acb))[0])
    else:
        # AWB data is required if using bytes.
        if data_awb == None:
            return False

        path_out = normpath(path_out)
    
    makedirs(path_out, exist_ok=True)

    try:
        if type(path_acb) == str:
            acbObj = ACB(path_acb)
        else:
            acbObj = DeferredACB(path_acb, data_awb)
    except FileNotFoundError:
        return False
    
    loops : List[Tuple[str, float]] = []

    def write_loops():
        with open(join(path_out, "metadata.csv"), "w+") as loop_out:
            loop_out.write("filename,loop_offset")
            for loop in loops:
                name, start = loop
                loop_out.write("\n" + str(name) + "," + str(start))

    files = []
    for file in acbObj.awb.getfiles():
        files.append(file)

    payload = acbObj.payload[0]

    name_dict = {}
    for key in payload["CueNameTable"]:
        _utf_type, name = key["CueName"]
        name_dict[key["CueIndex"][1]] = name

    force_remap = force_remap or (auto_remap and (len(files) != len(name_dict)))

    if not(force_remap):
        idx = 0

        for id in name_dict:
            extension = acbObj.get_extension(payload['WaveformTable'][idx]['EncodeType'][1])
            if extension == ".hca":
                hcaObj = HCA(files[idx])
                wav_data = bytearray(hcaObj.decode())
                if compress:
                    ogg_data, looped, start = wav_to_ogg_ffmpeg(wav_data, path_custom_ffmpeg=path_custom_ffmpeg)
                    if looped:
                        loops.append((name_dict[id] + ".ogg", start))

                    with open(join(path_out, name_dict[id] + ".ogg"), 'wb+') as out:
                        out.write(ogg_data)
                else:
                    with open(join(path_out, name_dict[id] + ".wav"), 'wb+') as out:
                        out.write(wav_data)
            idx += 1
        
        if compress:
            write_loops()
        return True
    
    cue_ref_info : List[Tuple[int, str]] = []

    for key in payload["CueTable"]:
        cue_ref_info.append((key["CueId"][1], name_dict[key["ReferenceIndex"][1]]))
    
    # idk how reliable this is :)
    # i don't really understand this format, theres many tables and some don't mean much for layton
    # ControlWorkArea1 could actually just be index instead
    synth_table_fetch : Dict[int, int] = {}
    for entry in payload["SynthTable"]:
        synth_table_fetch[entry["ControlWorkArea1"][1]] = int.from_bytes(entry["ReferenceItems"][1][2:], byteorder='big')

    for entry in synth_table_fetch:
        _cue_id, name = cue_ref_info[entry]
        target_track = synth_table_fetch[entry]
        extension = acbObj.get_extension(payload['WaveformTable'][target_track]['EncodeType'][1])
        if extension == ".hca":
            data = files[target_track]
            hcaObj = HCA(data)
            wav_data = bytearray(hcaObj.decode())

            if compress:
                ogg_data, looped, start = wav_to_ogg_ffmpeg(wav_data, path_custom_ffmpeg=path_custom_ffmpeg)
                if looped:
                    loops.append((name + ".ogg", start))

                with open(join(path_out, name + ".ogg"), 'wb+') as out:
                    out.write(ogg_data)
            else:
                with open(join(path_out, name + ".wav"), 'wb+') as out:
                    out.write(wav_data)
    
    if compress:
        write_loops()

    return True

def naive_decode_wav_from_awb(path_awb : Union[str, bytearray], path_out : str, compress : bool = True, path_custom_ffmpeg : Optional[str] = None) -> bool:
    """Convert an AWB file to WAV and retain original filename (different extension).

    This function only works for files containing a single sample.

    Compression requires ffmpeg. If ffmpeg is not installed correctly, compression will be disabled.

    Args:
        path_awb (str, bytearray): Path to AWB archive or raw bytes.
        path_out (str): Path to output directory. If using bytes for ACB, add the export folder name to the output path.
        compress (bool, optional): Export as OGG instead of WAV. OGG has comparable space / quality to the original and requires extra metadata. WAV is large but embeds metadata. Defaults to True.
        path_custom_ffmpeg (Optional[str], optional): Alternative path to FFMPEG executable. None to use system FFMPEG.

    Returns:
        bool: True if extraction was successful.
    """

    if path_custom_ffmpeg == None:
        test_ffmpeg_call = "ffmpeg"
    else:
        test_ffmpeg_call = path_custom_ffmpeg

    if subprocess.call("%s -version" % test_ffmpeg_call, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL, shell=True) != 0:
        compress = False

    if compress:
        extension = ".ogg"
    else:
        extension = ".wav"

    if type(path_awb) == str:
        path_awb = normpath(path_awb)
        path_out = join(normpath(path_out), splitext(basename(path_awb))[0] + extension)
    else:
        path_out = normpath(path_out) + extension

    makedirs(dirname(path_out), exist_ok=True)

    try:
        awbObj = AWB(path_awb)
    except FileNotFoundError:
        return False

    idx = 0
    for file in awbObj.getfiles():
        data_hca = file
        idx += 1
    
    if idx != 1:
        print("Bad: Multiple files in AWB!")
    elif idx == 0:
        return False

    hcaObj = HCA(data_hca)
    wavfile = hcaObj.decode()
    
    if compress:
        data, _looped, _loop_start = wav_to_ogg_ffmpeg(wavfile, quality=3, path_custom_ffmpeg=path_custom_ffmpeg)
        wavfile = data

    with open(path_out, 'wb+') as out:
        out.write(wavfile)
    return True
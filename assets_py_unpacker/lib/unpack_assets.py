from os import cpu_count, makedirs
from os.path import dirname, join, normpath
from typing import List, Optional, Tuple

try:
    from .lt2_decrypt import decrypt_asset as decrypt

except ModuleNotFoundError:
    print("Warning: Fast decryption routine not found. Decryption will be significantly slower. Please build with setup.py for faster decryption.")

    import numpy as np

    def decrypt(encrypted : bytearray, offset : int, size : int) -> bytearray:
        decrypted = bytearray(encrypted)
        offset = np.uint32(offset)
        offset += 0x45243
        for x in range(size):
            offset *= 0x41C64E6D
            offset += 0x3039
            offset = offset & 0xffffffff
            decrypted[x] = decrypted[x] ^ (offset >> 0x18)
        return decrypted

import time
import zipfile
from math import ceil
from threading import Thread

import cv2
import numpy as np

from . import OneLinePrinter

max_thread_count    : int   = max(1, min(ceil(cpu_count() * 0.5), cpu_count() - 1))

def extract_apk(path_apk : str, path_out : str, path_out_icon : str, valid_prefixes : List[str], find_icon : bool = False) -> bool:
    """Extracts assets from the LAYTON2 APK.

    Important game databases are stored as part of the APK. This is required to load the game.

    Args:
        path_apk (str): Path to LAYTON2 APK.
        path_out (str): Export path; will be created if non-existent.
        path_out_icon (str): Image export path; will be created if non-existent.
        valid_prefixes (List[str]): List of filename prefixes considered valid for extraction.
        find_icon (bool, optional): True to attempt to find best icon in APK. Defaults to False.

    Returns:
        bool: True if extraction was successful.
    """

    path_out = normpath(path_out)
    len_files = 0
    done = 0
    threads_active : List[Thread] = []
    printer = OneLinePrinter()

    if not(zipfile.is_zipfile(path_apk)):
        return False
    
    try:
        with zipfile.ZipFile(path_apk, 'r') as apk:
            path_targets = []
            path_icons = []

            for path in apk.namelist():
                path_norm = normpath(path)
                if find_icon and path_norm.startswith("res\\mipmap") and path_norm.endswith(".png"):
                    path_icons.append(path)
                else:
                    for prefix in valid_prefixes:
                        if path_norm.startswith(prefix + "\\"):
                            path_targets.append(path)
                            break
            
            len_files = len(path_targets)
                
            def thread_action(path_asset : str):
                target = join(path_out, normpath(path_asset)[7:])
                makedirs(dirname(target), exist_ok=True)

                with open(target, 'wb+') as out:
                    out.write(apk.read(path_asset))

            while len(path_targets) > 0:
                if len(threads_active) < max_thread_count:
                    thread = Thread(target=thread_action, args=(path_targets.pop(),))
                    thread.start()
                    threads_active.append(thread)
                else:
                    changed : bool = False
                    for idx in range(len(threads_active) - 1, -1, -1):
                        thread = threads_active[idx]
                        if not(thread.is_alive()):
                            thread.join()
                            threads_active.pop(idx)
                            changed = True
                            done += 1
                    
                    if not(changed):
                        time.sleep(0.01)
                    else:
                        printer.print("Extracting APK, ~%d/%d" % (done, len_files))
                
                for thread in threads_active:
                    thread.join()
                    done += 1
                    printer.print("Extracting APK, ~%d/%d" % (done, len_files))
                
                threads_active = []
            
            if find_icon:
                printer.print("Extracting APK, %d/%d, finding icon..." % (done, len_files))
                best_icon : np.ndarray = None
                best_count = 0

                for path in path_icons:
                    im_data = apk.read(path)
                    im : Optional[np.ndarray] = cv2.imdecode(np.fromstring(im_data, np.uint8), cv2.IMREAD_UNCHANGED)
                    if not(im is None):
                        count_px = im.shape[0] * im.shape[1]
                        if count_px:
                            best_count = count_px
                            best_icon = im
                
                if best_count > 0:
                    printer.print("Extracted APK, %d/%d!" % (done + 1, len_files + 1))
                    makedirs(dirname(path_out_icon), exist_ok=True)
                    cv2.imwrite(path_out_icon, best_icon)
                else:
                    printer.print("Extracted APK, %d/%d (no icon found)!" % (done, len_files))
            else:
                printer.print("Extracted APK, %d/%d!" % (done, len_files))
    
    except:
        print("")
        return False
    
    # Cleanup remaining threads, unless we're in error state there shouldn't be any
    for thread in threads_active:
        thread.join()
    
    print("")
    return True

def extract_obb(path_obb : str, path_out : str, valid_prefixes : List[str]) -> bool:
    """Extracts assets from the LAYTON2 OBB.

    The majority of the game is stored encrypted in the OBB. De-salting the data can be slow so expect this function to take some time.

    Args:
        path_obb (str): Path to LAYTON2 OBB.
        path_out (str): Export path; will be created if non-existent.
        valid_prefixes (List[str]): List of filename prefixes considered valid for extraction.

    Returns:
        bool: True if extraction was successful.
    """

    with open(path_obb, 'rb') as data_in:
        data_obb = bytearray(data_in.read())

    valid_prefixes_cleaned = []
    for prefix in valid_prefixes:
        valid_prefixes_cleaned.append(prefix.replace("\\", "/") + "/")

    def get_file_table() -> List[Tuple[str, int, int]]:

        def decode_file_table(table : bytearray) -> List[Tuple[str, int, int]]:
            f_count = int.from_bytes(table[:4], byteorder='little')

            output = []
            for idx in range(f_count):
                offset_root = (idx * 12) + 4
                offset_name = int.from_bytes(table[offset_root    :offset_root + 4],    byteorder='little')
                offset      = int.from_bytes(table[offset_root + 4:offset_root + 8],    byteorder='little')
                size        = int.from_bytes(table[offset_root + 8:offset_root + 12],   byteorder='little')

                name = ""
                while offset_name < len(table) and table[offset_name] != 0:
                    name += chr(table[offset_name])
                    offset_name += 1

                for prefix in valid_prefixes_cleaned:
                    if name.startswith(prefix):
                        output.append((name, offset, size))
                        break

            return output

        header = decrypt(data_obb[:0x14], 0, 0x14)

        if header[:4] != b'ARC1':
            return []

        offset = int.from_bytes(header[8:12], byteorder='little')
        tsize = int.from_bytes(header[12:16], byteorder='little')

        ftable = data_obb[offset:offset + tsize]
        return decode_file_table(decrypt(ftable, offset, tsize))

    def get_file_from_table(entry : Tuple[str, int, int]) -> bytearray:
        name, offset, length = entry

        if not(name.endswith(".mp4")):
            return decrypt(data_obb[offset:offset+length], offset, length)
        return data_obb[offset:offset+length]

    file_table = get_file_table()
    path_out = normpath(path_out)
    len_files = len(file_table)

    def thread_action(entry : Tuple[str, int, int]):
        name, _offset, _length = entry
        data = get_file_from_table(entry)

        target = join(path_out, normpath(name))
        makedirs(dirname(target), exist_ok=True)
        
        with open(target, 'wb+') as out:
            out.write(data)

    done = 0
    threads_active : List[Thread] = []
    printer = OneLinePrinter()

    while len(file_table) > 0:
        if len(threads_active) < max_thread_count:
            thread = Thread(target=thread_action, args=(file_table.pop(),))
            thread.start()
            threads_active.append(thread)
        else:
            changed : bool = False
            for idx in range(len(threads_active) - 1, -1, -1):
                thread = threads_active[idx]
                if not(thread.is_alive()):
                    thread.join()
                    threads_active.pop(idx)
                    changed = True
                    done += 1
            
            if not(changed):
                time.sleep(0.01)
            else:
                printer.print("Extracting OBB, ~%d/%d" % (done, len_files))
    
    for thread in threads_active:
        thread.join()
        done += 1
        printer.print("Extracting OBB, ~%d/%d" % (done, len_files))
    
    printer.print("Extracted OBB, %d/%d!" % (len_files, len_files))
    print("")
    return True
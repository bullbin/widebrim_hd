from lib import *
from os.path import join, splitext, dirname, exists, basename, exists
from os import walk, remove, getcwd
from sys import argv
import subprocess

PATH_OUT            : str = (join(dirname(getcwd()), "assets"))
PATH_INT_REL_FONT   : str = "data\\font\\font.dat"
PATH_REL_FONT       : str = "font.fnt"

def extract_game_assets(path_apk : str, path_obb : str, path_out : str) -> bool:
    apk_worked = extract_apk(path_apk, path_out)
    obb_worked = extract_obb(path_obb, path_out)
    if not(apk_worked):
        print("Failed to extract APK!")
    if not(obb_worked):
        print("Failed to extract OBB!")
    
    output = apk_worked and obb_worked
    if output:
        convert_audio(path_out)
        if convert_font_to_bnfont(join(path_out, PATH_INT_REL_FONT), join(path_out, PATH_REL_FONT)):
            print("Converted font!\n\nDone! You may now start widebrim_hd.")
        else:
            print("\nDone with errors: Font failed to convert. widebrim_hd will use a fallback.")
    else:
        print("\nFailed. Please check all the required files are present. widebrim_hd may not function correctly.")

    return apk_worked and obb_worked

def convert_audio(path_out : str) -> bool:
    
    targets_acb = []
    targets_awb = []
    to_delete = []

    if subprocess.call("ffmpeg -version", stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL, shell=True) != 0:
        print("FFMPEG is not installed correctly. Audio compression has been disabled - expect huge file sizes!")

    printer = OneLinePrinter()

    for path, _sub, files in walk(path_out):
        for name in files:
            path_full = join(path, name)
            extension = splitext(path_full)[-1]
            
            if extension == ".acb":
                targets_acb.append(path_full)
            elif extension == ".awb":
                targets_awb.append(path_full)
            elif extension == ".acf":           # We're gutting the original criware audio engine, delete this too
                to_delete.append(path_full)
    
    printer.print("Converting audio libraries...")
    
    for idx, target in enumerate(targets_acb):
        printer.print("Converting library %d/%d: %s" % (idx + 1, len(targets_acb), basename(target)))
        naive_decode_wav_from_acb(target, dirname(target))
        ext_db = splitext(target)[0] + ".awb"
        to_delete.append(ext_db)
    
    for target in to_delete:
        while target in targets_awb:
            targets_awb.remove(target)

    to_delete.extend(targets_acb)

    printer.print("Converted audio libraries!")

    print("")
    printer = OneLinePrinter()
    printer.print("Converting audio samples...")

    for idx, target in enumerate(targets_awb):
        printer.print("Converting sample %d/%d: %s" % (idx + 1, len(targets_awb), basename(target)))
        naive_decode_wav_from_awb(target, dirname(target))
        to_delete.append(target)
    
    printer.print("Converted audio samples!")
    
    print("")
    printer = OneLinePrinter()
    printer.print("Removing source audio...")

    for idx, target in enumerate(to_delete):
        if exists(target):
            printer.print("Removing %d/%d: %s" % (idx + 1, len(to_delete), basename(target)))
            remove(target)
    
    printer.print("Removed source audio!")
    print("")

    return True

def do():
    print("widebrim_hd asset extractor 0.0.1b\n")


    if len(argv) < 3:
        print("Usage: Specify OBB and APK paths with extensions in any order, e.g., \n\n\tpython install_apk_obb.py <path_apk> <path_obb>\n")
        return

    path_apk = ""
    path_obb = ""
    
    for path in argv[1:]:
        if exists(path):
            ext = splitext(path)[-1]
            if ext == ".obb":
                path_obb = path
            elif ext == ".apk":
                path_apk = path
        
            if path_obb != "" and path_apk != "":
                break
    
    if path_apk != "" and path_obb != "":
        extract_game_assets(path_apk, path_obb, PATH_OUT)
    else:
        if path_apk != "" and path_obb == "":
            print("Failed. Missing OBB path.")
        elif path_obb != "" and path_apk == "":
            print("Failed. Missing APK path.")
        else:
            print("Failed. Supplied paths were invalid.")

if __name__ == "__main__":
    do()
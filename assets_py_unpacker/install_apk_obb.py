import argparse
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from os import getcwd, remove, walk
from os.path import basename, dirname, exists, join, normpath, splitext
from typing import List, Optional, Tuple
from xml.etree.ElementTree import ParseError

from lib import (OneLinePrinter, convert_font_to_bmfont, decode_axml_to_xml,
                 extract_apk, extract_obb, get_version_information,
                 is_apk_base, is_apk_install_block, naive_decode_wav_from_acb,
                 naive_decode_wav_from_awb)

PATH_OUT            : str = join(dirname(getcwd()), "assets")
PATH_OUT_FONT       : str = join(dirname(getcwd()), "font")
PATH_OUT_ICON       : str = join(dirname(getcwd()), "icon.png")
PATH_INT_REL_FONT   : str = "data\\font\\font.dat"
PATH_REL_FONT       : str = "font.fnt"

def check_extension(filepath : str, extension : str) -> bool:
	return splitext(filepath)[1] == extension

def get_manifest(filepath_to_apk : str) -> Optional[ET.Element]:
	if not(zipfile.is_zipfile(filepath_to_apk)):
		return None
	
	with zipfile.ZipFile(filepath_to_apk) as apk_data:
		try:
			with apk_data.open("AndroidManifest.xml") as targ_manifest:
				return ET.fromstring(decode_axml_to_xml(targ_manifest.read()))
		except (KeyError, ParseError) as e:
			pass
	return None

print("widebrim_hd asset extractor 0.1.0a\n")

parser = argparse.ArgumentParser()
parser.add_argument("path_base_apk", help="path to base game APK")
parser.add_argument("path_additional_data", help="path to either OBB or InstallAsset APK")
parser.add_argument("--jp", help="filter and include Japanese install files", action="store_true")
parser.add_argument("--en_eu", help="filter and include English (Europe) install files", action="store_true")
parser.add_argument("--en_us", help="filter and include English (United States) install files", action="store_true")
parser.add_argument("--es", help="filter and include Spanish install files", action="store_true")
parser.add_argument("--fr", help="filter and include French install files", action="store_true")
parser.add_argument("--it", help="filter and include Italian install files", action="store_true")
parser.add_argument("--de", help="filter and include German install files", action="store_true")
parser.add_argument("--nl", help="filter and include Dutch install files", action="store_true")
parser.add_argument("--ko", help="filter and include Korean install files", action="store_true")
parser.add_argument("-f", "--ffmpeg_path", help="full path of alternative FFMPEG executable", type=str)

args = parser.parse_args()

def get_starters_for_language(jp : bool, en_eu : bool, en_us : bool, es : bool, fr : bool, it : bool, de : bool, nl : bool, ko : bool) -> List[str]:
	output = [normpath("assets/data")]

	combos : List[Tuple[str, str]] = []
	if jp	: combos.append(("ja", "JP"))
	if en_eu: combos.append(("en", "EU"))
	if en_us: combos.append(("en", "US"))
	if es	: combos.append(("es", "EU"))
	if fr	: combos.append(("fr", "EU"))
	if it	: combos.append(("it", "EU"))
	if de	: combos.append(("de", "EU"))
	if nl	: combos.append(("nl", "EU"))
	if ko	: combos.append(("ko", "EU"))

	for language, region in combos:
		for path in ["assets/data-%s-%s" % (language, region),
			   		 "assets/data-%s" % language,
					 "assets/data-%s" % region]:
			if path not in output:
				output.append(normpath(path))

	return output

def do():
	base_manifest = get_manifest(args.path_base_apk)
	if base_manifest == None:
		return
	
	if not(is_apk_base(base_manifest)):
		return
	
	version, package_name, wants_apk = get_version_information(base_manifest)
	if not(package_name.startswith("com.Level5.LT2R")):
		print("Installation error: base APK is not LT2R (LAYTON2HD).")
		return
	
	print("Base APK Metadata\n\tPackage\t%s\n\tVersion\t%s\n\tBundle\t%s\n" % (package_name, version, "Split APK" if wants_apk else "OBB"))

	extra_manifest = get_manifest(args.path_additional_data)
	if (extra_manifest == None and wants_apk) or (not(wants_apk) and extra_manifest != None):
		print("Installation error: additional data doesn't belong to base APK.")
		return

	if sum([args.jp, args.en_eu, args.en_us, args.es, args.fr, args.it, args.de, args.nl, args.ko]) == 0:
		starters = get_starters_for_language(True, True, True, True, True, True, True, True, True)
	else:
		starters = get_starters_for_language(args.jp, args.en_eu, args.en_us, args.es, args.fr, args.it, args.de, args.nl, args.ko)

	if wants_apk:
		if not(is_apk_install_block(extra_manifest)):
			print("Installation error: could not verify whether additional APK is InstallAssets.")
			return
		
		_temp, extra_package_name, extra_wants_apk = get_version_information(extra_manifest)
		if extra_package_name != package_name:
			print("Installation error: additional APK belongs to %s but base APK is %s." % (extra_package_name, package_name))
			return
		if extra_wants_apk:
			print("Installation error: additional APK requested unsupported fusion with more data.")
			return
	else:
		pass

	data_extracted = extract_apk(args.path_base_apk, PATH_OUT, PATH_OUT_ICON, starters, True)
	if not(data_extracted):
		print("Installation error: base APK could not be extracted.")
		return
	
	if wants_apk:
		data_extracted = extract_apk(args.path_additional_data, PATH_OUT, PATH_OUT_ICON, starters)
	else:
		data_extracted = extract_obb(args.path_additional_data, PATH_OUT, [x[7:] for x in starters])
	
	if not(data_extracted):
		print("Installation error: additional data could not be extracted.")
		return
	
	font_success = convert_font_to_bmfont(join(PATH_OUT, PATH_INT_REL_FONT), join(PATH_OUT_FONT, PATH_REL_FONT))
	audio_success = convert_audio(PATH_OUT, args.ffmpeg_path)

	if font_success and audio_success:
		print("\nInstallation complete! You may now start widebrim_hd.")
	elif font_success:
		print("\nInstallation failed: audio conversion error.")
	elif audio_success:
		print("\nInstallation failed: font conversion error.")
	else:
		print("\nInstallation failed: audio and font conversion error.")

def convert_audio(path_out : str, path_alt_ffmpeg : Optional[str]) -> bool:
	
	use_system_ffmpeg = path_alt_ffmpeg == None
	
	if path_alt_ffmpeg != None:
		if subprocess.call("%s -version" % path_alt_ffmpeg, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL, shell=True) != 0:
			print("Custom FFMPEG at %s could not be called correctly, falling back to system FFMPEG!" % path_alt_ffmpeg)
			use_system_ffmpeg = True
			path_alt_ffmpeg = None
	
	if use_system_ffmpeg and subprocess.call("ffmpeg -version", stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL, shell=True) != 0:
		print("FFMPEG is not installed correctly. Audio compression has been disabled - expect huge file sizes!")

	targets_acb = []
	targets_awb = []
	to_delete = []

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
		if not(naive_decode_wav_from_acb(target, dirname(target), path_custom_ffmpeg=path_alt_ffmpeg)):
			return False
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
		if not(naive_decode_wav_from_awb(target, dirname(target), path_custom_ffmpeg=path_alt_ffmpeg)):
			return False
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

do()
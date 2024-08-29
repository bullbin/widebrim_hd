import xml.etree.ElementTree as ET
from io import BytesIO
from struct import unpack
from sys import getdefaultencoding
from typing import List, Tuple, Union

def decode_axml_to_xml(path_or_bytes : Union[str, bytes], verbose : bool = False) -> str:
    """Decode binary XML as used by AndroidManifest back to a usable XML output.

    This method mimicks the output from ClassyShark and is very hacky. It omits namespace
    information, will not decode complex attributes and may break with later versions of
    Android. This is only recommended for decoding immediate attributes.

    Args:
        path_or_bytes (Union[str, bytes]): Path or bytes of encoded AndroidManifest.xml.
        verbose (bool, optional): True to enable chunk information for debugging. Defaults to False.

    Raises:
        IOError: Raised if any step of decoding fails, e.g., file wasn't found, file was invalid,
        internal reference out of bounds, etc.

    Returns:
        str: Decoded XML corresponding to input. Will not match original but will contain same data.
    """

    # Credit : https://justanapplication.wordpress.com/category/android/android-binary-xml/

    xml_string_bank  : List[str] = []
    xml_decoded : List[Union[XmlStartElement, XmlEndElement]] = []

    class XmlUnsupportedException(Exception):
        pass

    class XmlResValue():
        def __init__(self, id_type : int, data : bytes):
            self.id_type : int = id_type
            self.data : Union[bytes, str, float] = data
            self.needs_decoding : bool = True
        
        def decode(self, string_bank : List[str]):
            if self.needs_decoding:
                if self.id_type == 0x3:
                    self.data = string_bank[int.from_bytes(self.data, byteorder='little')]
                elif self.id_type == 0x4:
                    self.data = unpack("<f", self.data)[0]
                elif self.id_type == 0x10:
                    self.data = self.data[0]
                elif self.id_type == 0x12:
                    self.data = self.data[0] == 255
                else:
                    return
                
                self.needs_decoding = False

    class XmlAttribute():
        def __init__(self, idx_pool : int, idx_name : int, idx_value : int, res_type : XmlResValue):
            self.idx_pool : int = idx_pool
            self.idx_name : int = idx_name
            self.idx_raw_value : int = idx_value
            self.res_type : XmlResValue = res_type
    
    class XmlStartElement():
        def __init__(self, idx_namespace : int, idx_name : int, idx_attrib_id : int, idx_attrib_class : int, idx_attrib_style : int):
            self.idx_namespace : int = idx_namespace
            self.idx_name : int = idx_name
            self.idx_attrib_id : int = idx_attrib_id
            self.idx_attrib_class : int = idx_attrib_class
            self.idx_attrib_style : int = idx_attrib_style
            self.attribs : List[XmlAttribute] = []

    class XmlEndElement():
        def __init__(self, idx_pool : int, idx_name : int):
            self.idx_pool : int = idx_pool
            self.idx_name : int = idx_name

    def parse_xml_string_block(header : bytes, data : bytes):
        count_strings = int.from_bytes(header[0:4], byteorder='little')
        flags = int.from_bytes(header[8:12], byteorder='little')
        if flags & 0x1 > 0:
            raise XmlUnsupportedException("String decoding failed: Unsupported string flag (sort mode enabled).")
        if (flags >> 8) & 0x1 > 0:
            charset = 'utf-8'
            encoding_len = 1
        else:
            charset = 'utf-16'
            encoding_len = 2

        offset_encoded_strings = count_strings * 4
        for idx_string in range(count_strings):
            offset_string = int.from_bytes(data[idx_string * 4:(idx_string + 1) * 4], byteorder='little')
            len_str = int.from_bytes(data[offset_encoded_strings + offset_string : offset_encoded_strings + offset_string + 2], byteorder='little')
            encoded = data[offset_encoded_strings + offset_string + 2 : offset_encoded_strings + offset_string + 2 + (len_str * encoding_len)]
            xml_string_bank.append(encoded.decode(charset))

    def parse_xml_start_element(header : bytes, data : bytes):
        idx_ns = int.from_bytes(data[0:4], byteorder='little', signed=True)
        idx_name = int.from_bytes(data[4:8], byteorder='little')
        start_attribute = int.from_bytes(data[8:10], byteorder='little')
        count_attribute = int.from_bytes(data[12:14], byteorder='little')
        idx_attribute_id = int.from_bytes(data[14:16], byteorder='little')
        idx_attribute_class = int.from_bytes(data[16:18], byteorder='little')
        idx_attribute_style = int.from_bytes(data[18:20], byteorder='little')

        xml_element = XmlStartElement(idx_ns, idx_name, idx_attribute_id, idx_attribute_class, idx_attribute_style)

        offset = start_attribute
        for _idx_attrib in range(count_attribute):
            attrib_size = int.from_bytes(data[offset+12:offset+14], byteorder='little')
            attrib_type = int.from_bytes(data[offset+15:offset+16])

            xml_element.attribs.append(XmlAttribute(int.from_bytes(data[offset:offset + 4], byteorder='little', signed=True),
                                                    int.from_bytes(data[offset + 4:offset + 8], byteorder='little', signed=True),
                                                    int.from_bytes(data[offset + 8:offset + 12], byteorder='little', signed=True),
                                                    XmlResValue(attrib_type, data[offset+16:offset+20])))
            offset += 12 + attrib_size
        
        xml_decoded.append(xml_element)

    def parse_xml_end_element(header : bytes, data : bytes):
        idx_namespace = int.from_bytes(data[0:4], byteorder='little', signed=True)
        idx_name = int.from_bytes(data[4:8], byteorder='little')
        xml_decoded.append(XmlEndElement(idx_namespace, idx_name))

    def open_file():
        if type(path_or_bytes) is str:
            return open(path_or_bytes, 'rb')
        else:
            return BytesIO(path_or_bytes)

    try:
        with open_file() as axml:

            file_len = 0

            while True:
                offset_now = axml.tell()
                block_id = int.from_bytes(axml.read(2), byteorder='little')
                header_size = int.from_bytes(axml.read(2), byteorder='little')
                chunk_size = int.from_bytes(axml.read(4), byteorder='little') - header_size

                if block_id == 3:
                    file_len = offset_now + header_size + chunk_size
                    axml.seek(offset_now + header_size)
                    continue
                
                header = axml.read(header_size - 8)
                chunk = axml.read(chunk_size)

                if verbose:
                    print(hex(offset_now), "Block ID", hex(block_id))

                if block_id == 0x1:
                    parse_xml_string_block(header, chunk)
                elif block_id == 0x102:
                    parse_xml_start_element(header, chunk)
                elif block_id == 0x103:
                    parse_xml_end_element(header, chunk)
                elif verbose:
                    print("\tSkipped, unsupported!")

                if axml.tell() >= file_len:
                    break
    
    except (IOError, IndexError, FileNotFoundError, XmlUnsupportedException) as e:
        raise IOError("Error loading XML file.")

    out_xml = '<?xml version="1.0" encoding="%s"?>\n' % getdefaultencoding().upper()
    nest_depth = 0
    nest_on_enter = 2
    for value in xml_decoded:
        if type(value) is XmlStartElement:
            out_xml += "%s<%s\n" % (" " * nest_depth, xml_string_bank[value.idx_name])
            nest_depth += nest_on_enter
            for attrib in value.attribs:
                attrib.res_type.decode(xml_string_bank)
                if attrib.res_type.needs_decoding:
                    # Not accurate or correct but the data I want at this point works
                    out_xml += "%s%s='%s'\n" % (" " * (nest_depth + nest_on_enter), xml_string_bank[attrib.idx_name], attrib.res_type.data.hex())
                else:
                    out_xml += "%s%s='%s'\n" % (" " * (nest_depth + nest_on_enter), xml_string_bank[attrib.idx_name], attrib.res_type.data)
            out_xml = out_xml[:-1] + ">\n"
        elif type(value) is XmlEndElement:
            nest_depth = max(nest_depth - nest_on_enter, 0)
            out_xml += "%s</%s>\n" % (" " * nest_depth, xml_string_bank[value.idx_name])
    out_xml = out_xml[:-1]
    return out_xml

def is_apk_base(apk_base_tree : ET.Element) -> bool:
    """Returns whether APK corresponds to base (i.e., code and not assets) APK for a title.

    This works by checking if split-related information is contained inside the manifest and may
    not be correct.

    Args:
        apk_base_tree (ET.Element): Root element of AndroidManifest XML (corresponding to 'manifest').

    Returns:
        bool: True if APK is likely the base APK.
    """

    if "isFeatureSplit" in apk_base_tree.attrib:
        return apk_base_tree.attrib["isFeatureSplit"].lower() == "false"
    return True

def is_apk_install_block(apk_base_tree : ET.Element) -> bool:
    """Returns whether APK corresponds to game assets for a title.

    This works by checking both the split APK title and whether it identifies itself as a split; it
    may not be correct.

    Args:
        apk_base_tree (ET.Element): Root element of AndroidManifest XML (corresponding to 'manifest').

    Returns:
        bool: True if APK is likely the asset APK.
    """

    if "isFeatureSplit" in apk_base_tree.attrib and "split" in apk_base_tree.attrib:
        return apk_base_tree.attrib["isFeatureSplit"].lower() == "true" and apk_base_tree.attrib["split"] == "InstallAssets"
    return False

def get_version_information(apk_base_tree : ET.Element) -> Tuple[str, str, bool]:
    """Get key information for an APK.

    Args:
        apk_base_tree (ET.Element): Root element of AndroidManifest XML (corresponding to 'manifest').

    Returns:
        Tuple[str, str, bool]: (Version code, package name, True if it requires additional split APKs)
    """

    version = "1.0.0"
    package = "com.Level5.LT2R"
    if "versionName" in apk_base_tree.attrib:
        version = apk_base_tree.attrib["versionName"]
    if "package" in apk_base_tree.attrib:
        package = apk_base_tree.attrib["package"]
    
    is_split_required = False
    if (apk_base_tree := apk_base_tree.find("application"), apk_base_tree != None):
        if "isSplitRequired" in apk_base_tree.attrib:
            is_split_required = apk_base_tree.attrib["isSplitRequired"].lower() == "true"

    return (version, package, is_split_required)
from typing import Dict, Union
import numpy as np
import cv2
from os.path import splitext, normpath, basename

# TODO - This has only been tested on the EU ROM

# Credit - madhatter, https://github.com/bullbin/madhatter/blob/main/hat_io/binary.py
class BinaryReader():

    def __init__(self, filename : str):
        self.pos = 0
        with open(filename, 'rb') as dataIn:
            self.data = bytearray(dataIn.read())

    def read(self, length) -> bytearray:
        self.pos += length
        return self.data[self.pos - length:self.pos]
    
    def readInt(self, length, signed=True) -> int:
        return int.from_bytes(self.read(length), byteorder = 'little', signed=signed)
    
    def readUInt(self, length) -> int:
        return self.readInt(length, signed=False)

    def readU16(self) -> int:
        return self.readUInt(2)

    def readU32(self) -> int:
        return self.readUInt(4)
    
def convert_font_to_bmfont(path_in : str, path_out : str) -> bool:
    """Convert fonts in the Layton2HD format to the text variant of the BMFont format.

    Args:
        path_in (str): Path to Layton font.
        path_out (str): Export path. If extension is not fnt, it will be renamed to force it.

    Returns:
        bool: True if converted successfully and files created, False otherwise.
    """

    def pad(in_str : str, len_extra : int) -> str:
        return in_str + " " * (len_extra - len(in_str))

    CHARS_PER_ROW = 26

    path_in = normpath(path_in)
    path_out = normpath(path_out)

    try:
        dat_font = BinaryReader(path_in)
    except (FileNotFoundError, IOError):
        return False

    # Credit - initial research by https://github.com/creativelynameduser,
    #     https://github.com/bullbin/widebrim_hd/issues/1
    count_symbols = dat_font.readU32()
    weight = dat_font.readU16()
    pad_x = dat_font.readU16()          # Y is also padded but all on same line
    atlas_width = dat_font.readU16()
    atlas_height = dat_font.readU16()
    size_cell = weight + 2 * pad_x

    chars_symbol = []
    chars_widths = []

    for _i in range(count_symbols):
        symbol = dat_font.read(2).decode('utf-16')
        symbol_width = dat_font.readU16()

        # Empty symbol is on end, skip it because Python interprets it as a null string
        if len(symbol) != 0:
            chars_symbol.append(symbol)
            chars_widths.append(symbol_width)
    
    if len(chars_symbol) == 0 or atlas_height == 0 or atlas_width == 0:
        return False

    image = np.zeros(shape=(atlas_height, atlas_width), dtype=np.uint8)
    for y in range(atlas_height):
        for x in range(atlas_width):
            image[y,x] = dat_font.readUInt(1)

    # Image is padded to powers of two, not needed for our purposes
    image = image[:int(np.ceil(count_symbols / CHARS_PER_ROW)) * size_cell,
                :CHARS_PER_ROW * size_cell]

    path_image_out = splitext(path_out)[0] + "_0.png"
    if splitext(path_out)[1] != ".fnt":
        path_out = splitext(path_out)[0] + ".fnt"

    dict_info : Dict[str, Union[str, int]] = {"face":'"Layton2HD"',
                                              "size":weight,
                                              "bold":"0",
                                              "italic":"0",
                                              "charset":'""',
                                              "unicode":"1",
                                              "stretchH":"100",
                                              "smooth":"1",
                                              "aa":"1",
                                              "padding":"%d,%d,%d,%d" % (0,0,0,0),  # TODO - Try line spacing
                                              "spacing":"1,1",
                                              "outline":"0"}
    dict_common : Dict[str, Union[str, int]] = {"lineHeight":size_cell,
                                                "base":size_cell - pad_x,   # Not completely accurate but fine
                                                "scaleW":image.shape[1],
                                                "scaleH":image.shape[0],
                                                "pages":"1",
                                                "packed":"0",
                                                "alphaChnl":"1",
                                                "redChnl":"0",
                                                "greenChnl":"0",
                                                "blueChnl":"0"}
    
    try:
        # Credit - BMFont documentation (and example export), https://www.angelcode.com/products/bmfont/doc/file_format.html
        with open(path_out, 'w+', encoding="utf-8") as fnt:
            fnt.write("info")
            for key in dict_info:
                fnt.write(" %s=%s" % (key, dict_info[key]))
            fnt.write("\n")
            fnt.write("common")
            for key in dict_common:
                fnt.write(" %s=%s" % (key, dict_common[key]))
            fnt.write('\npage id=0 file="%s"\nchars count=%d' % (basename(path_image_out), len(chars_symbol)))
            
            index = 0
            for symbol, width in zip(chars_symbol, chars_widths):
                x = (index % CHARS_PER_ROW) * size_cell
                y = (index // CHARS_PER_ROW) * size_cell

                fnt.write("\nchar ")
                fnt.write("id=%s" % pad(str(ord(symbol)), 5))
                fnt.write("x=%s" % pad(str(x + pad_x), 6))
                fnt.write("y=%s" % pad(str(y), 6))
                fnt.write("width=%s" % pad(str(width), 6))
                fnt.write("height=%s" % pad(str(size_cell), 6))
                fnt.write("xoffset=0     ")
                fnt.write("yoffset=0     ")
                fnt.write("xadvance=%s" % pad(str(width), 6))
                fnt.write("page=0  chnl=15")

                index += 1
            fnt.write("\nkernings count=0\n")
    except IOError:
        return False
    
    cv2.imwrite(path_image_out, image)
    return True
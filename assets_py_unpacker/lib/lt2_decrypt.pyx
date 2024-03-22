from cpython.bytearray cimport PyByteArray_FromStringAndSize, PyByteArray_AsString
from libc.stdlib cimport malloc

cpdef bytearray decrypt_asset(bytearray encrypted, unsigned int offset, unsigned int size):
    cdef unsigned char* p_enc = <unsigned char*>PyByteArray_AsString(encrypted)
    cdef unsigned char* p_dec = <unsigned char*>malloc(size * sizeof(unsigned char))
    
    offset += 0x45243
    for x in range(size):
        offset *= 0x41C64E6D
        offset += 0x3039
        offset = offset & 0xffffffff
        p_dec[x] = p_enc[x] ^ (offset >> 0x18)

    return PyByteArray_FromStringAndSize(<char*>p_dec, size)
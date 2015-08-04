
from misc_types cimport *


cdef extern from "cx.h":
    ctypedef uint32 rflags_t
    ctypedef uint8  cxdtype_t

    ctypedef int32  cx_ival_t
    ctypedef int64  cx_lval_t
    ctypedef double cx_dval_t

    ctypedef struct cx_time_t:
        int sec
        int nsec


    #cxdtype_t management

    enum:
        #/* Encoding scheme */
        CXDTYPE_SIZE_MASK = 0x7
        CXDTYPE_REPR_MASK = 0x78
        CXDTYPE_REPR_SHIFT = 3
        CXDTYPE_USGN_MASK = 0x80

        #/* Representations */
        CXDTYPE_REPR_UNKNOWN = 0
        CXDTYPE_REPR_INT     = 1
        CXDTYPE_REPR_FLOAT   = 2
        CXDTYPE_REPR_TEXT    = 3

    enum:
        CXDTYPE_UNKNOWN = 0
        CXDTYPE_INT8    = 8
        CXDTYPE_INT16   = 9
        CXDTYPE_INT32   = 10
        CXDTYPE_INT64   = 11
        CXDTYPE_UINT8   = 136
        CXDTYPE_UINT16  = 137
        CXDTYPE_UINT32  = 138
        CXDTYPE_UINT64  = 139
        CXDTYPE_SINGLE  = 18
        CXDTYPE_DOUBLE  = 19
        CXDTYPE_TEXT    = 152
        CXDTYPE_UCTEXT  = 154

# cx data types can be encoded by this function
#cdef cxdtype_t ENCODE_DTYPE(int bytesize, int repr, int usgn):
#    cdef:
#        cxdtype_t a=7
#    if bytesize == 1: a = 0
#    if bytesize == 2: a = 1
#    if bytesize == 4: a = 2
#    if bytesize == 8: a = 3
#    a |= (repr << CXDTYPE_REPR_SHIFT)
#    if usgn:
#        a |= CXDTYPE_USGN_MASK
#    return a

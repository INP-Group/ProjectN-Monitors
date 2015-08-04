# cython: profile=False
# cython: c_string_type=bytes, c_string_encoding=ascii
world = "hi"

from monitors.cx4.cython_wrapper.cda cimport *
cimport libc.math as math
from PyQt5.QtCore import QObject, pyqtSignal

# copy enums to python syde
PY_CXDTYPE_UNKNOWN = CXDTYPE_UNKNOWN
PY_CXDTYPE_INT8 = CXDTYPE_INT8
PY_CXDTYPE_INT16 = CXDTYPE_INT16
PY_CXDTYPE_INT32 = CXDTYPE_INT32
PY_CXDTYPE_INT64 = CXDTYPE_INT64
PY_CXDTYPE_UINT8 = CXDTYPE_UINT8
PY_CXDTYPE_UINT16 = CXDTYPE_UINT16
PY_CXDTYPE_UINT32 = CXDTYPE_UINT32
PY_CXDTYPE_UINT64 = CXDTYPE_UINT64
PY_CXDTYPE_SINGLE = CXDTYPE_SINGLE
PY_CXDTYPE_DOUBLE = CXDTYPE_DOUBLE
PY_CXDTYPE_TEXT = CXDTYPE_TEXT
PY_CXDTYPE_UCTEXT = CXDTYPE_UCTEXT

PY_CDA_REF_R_UPDATE = CDA_REF_R_UPDATE
PY_CDA_REF_EVMASK_UPDATE = CDA_REF_EVMASK_UPDATE
PY_CDA_REF_R_STATCHG = CDA_REF_R_STATCHG
PY_CDA_REF_EVMASK_STATCHG = CDA_REF_EVMASK_STATCHG
PY_CDA_REF_R_STRSCHG = CDA_REF_R_STRSCHG
PY_CDA_REF_EVMASK_STRSCHG = CDA_REF_EVMASK_STRSCHG
PY_CDA_REF_R_RDSCHG = CDA_REF_R_RDSCHG
PY_CDA_REF_EVMASK_RDSCHG = CDA_REF_EVMASK_RDSCHG
PY_CDA_REF_R_LOCKSTAT = CDA_REF_R_LOCKSTAT
PY_CDA_REF_EVMASK_LOCKSTAT = CDA_REF_EVMASK_LOCKSTAT
PY_CDA_REF_R_RSLVSTAT = CDA_REF_R_RSLVSTAT
PY_CDA_REF_EVMASK_RSLVSTAT = CDA_REF_EVMASK_RSLVSTAT


# union to get not pretyped data
# it's not CX anytype....no text or unknown type
ctypedef union mixed_data:
    int8   i8
    int16  i16
    int32  i32
    int64  i64
    uint8  u8
    uint16 u16
    uint32 u32
    uint64 u64
    float  f32
    double f64


# struct to extend private pointer
ctypedef struct privptr_ext:
    void *objptr
    void *userptr

# forward declared classes
# this is required for callbacks
cdef class cda_base_chan
cdef class sdchan # scalar double chan
cdef class sichan # scalar int32 chan
cdef class schan  # general scalar chan

cdef void cda_check_exception(int code):
    if code < 0:
        raise Exception("Error: %s, errcode: %s" % (cda_last_err(), code))

cdef void convert_time(cx_time_t *in_time, int64 *out_time):
    out_time[0] = <int64>in_time.sec * 1000000 + in_time.nsec / 1000

cdef void evproc_cont(int uniq, void *privptr1, cda_context_t cid, int reason, int info_int, void *privptr2):
    pass

# C callback function for ref's (channels)
cdef void evproc_rslvstat(int uniq, void *privptr1, cda_dataref_t ref, int reason, void *info_ptr, void *privptr2) with gil:
    chan = <cda_base_chan>((<privptr_ext*>privptr2)[0].objptr)
    if <long>info_ptr == 0: # this is channel not found
        chan.notFound = -1
        print("Error: channel not found %s.%s" % (chan.base, chan.spec))


cdef void evproc_sdchan(int uniq, void *privptr1, cda_dataref_t ref, int reason, void *info_ptr, void *privptr2) with gil:
    (<sdchan>( (<privptr_ext*>privptr2)[0].objptr )).cb()

cdef void evproc_sichan(int uniq, void *privptr1, cda_dataref_t ref, int reason, void *info_ptr, void *privptr2) with gil:
    (<sichan>( (<privptr_ext*>privptr2)[0].objptr )).cb()

cdef void evproc_schan(int uniq, void *privptr1, cda_dataref_t ref, int reason, void *info_ptr, void *privptr2) with gil:
    (<schan>( (<privptr_ext*>privptr2)[0].objptr )).cb()


# classes

cdef class event:
    cdef:
        int evmask
        void *evproc
        privptr_ext ptrs

    @staticmethod
    cdef event create(int evmask, void *evproc, void *objptr, void *userptr):
        ev = event()
        ev.evmask = evmask
        ev.evproc = evproc
        ev.ptrs.objptr = objptr
        ev.ptrs.userptr = userptr
        return ev

    cdef int feasible(self):
        if self.evmask == 0 or self.evproc == NULL or self.ptrs.objptr == NULL: return 0
        return 1

    def __cmp__(self, event other):
        if self.evmask == other.evmask and self.evproc == other.evproc and \
            self.ptrs.objptr == other.ptrs.objptr and self.ptrs.userptr == other.ptrs.userptr:
            return 0
        return 1


cdef class cda_object:
    cdef:
        list events

    def __init__(self):
        self.events = []

    cdef int add_event(self,int evmask, void *evproc, void *objptr, void *userptr):
        ev = event.create(evmask, evproc, objptr, userptr)

        if not ev.feasible() or self.search_event(ev) is not None:
            # event will not run or already exist
            return False
        self.register_event(ev)
        self.events.append(ev)
        return True

    cdef int del_event(self, int evmask, void *evproc, void *objptr, void *userptr):
        cdef:
            event ev, stored_ev
        ev = event.create(evmask, evproc, objptr, userptr)
        stored_ev = self.search_event(ev)
        if stored_ev is None:
            # event does not exist
            return False
        self.events.remove(stored_ev)
        self.unregister_event(stored_ev)
        return True

    cdef search_event(self, event ev):
        return next((x for x in self.events if x==ev ), None)

    cdef void register_event(self,event ev):
        return

    cdef void unregister_event(self,event ev):
        return


cdef class cda_context(cda_object):
    cdef:
        int ret # temp for returned value
        readonly cda_context_t cid
        readonly list chans
        readonly char* c_defpfx

    def __init__(self, defpfx="v2cx::", evmask=0, evproc=None, privptr2=None):
        super(cda_context, self).__init__()
        self.chans = []

        ascii_pfx = defpfx.encode("ascii") # encode to ascii
        self.c_defpfx = ascii_pfx  # convert to char*

        self.ret = cda_new_context(0, NULL, self.c_defpfx, 0, NULL, 0, evproc_cont, NULL)

        cda_check_exception(self.ret)
        self.cid = self.ret
        self.add_event(evmask, <void*>evproc_cont, <void*>self, <void*>privptr2)

    def __dealloc__(self):
        pass

    cdef close(self):
        self.ret = cda_del_context(self.cid)
        cda_check_exception(self.ret)
        self.cid = 0

    cdef void register_event(self, event ev):
        self.ret = cda_add_context_evproc(self.cid, ev.evmask, <cda_context_evproc_t>(ev.evproc), &ev.ptrs)
        cda_check_exception(self.ret)

    cdef void unregister_event(self, event ev):
        self.ret = cda_del_context_evproc(self.cid, ev.evmask, <cda_context_evproc_t>(ev.evproc), &ev.ptrs)
        cda_check_exception(self.ret)


default_context = cda_context()

# classes for channels

# wrapper-class for low-level functions and channel registration
cdef class cda_base_chan(cda_object):
    cdef:
        # used properties
        int max_nelems
        cda_dataref_t ref
        cxdtype_t dtype
        char *c_base
        char *c_spec
        readonly int ret
        readonly str base, spec
        object context
        #error states
        int notFound # 0 - unknown, 1 found, -1 not found

    def __init__(self, context, str base, str spec, cxdtype_t dtype, int max_nelems):
        cda_object.__init__(self)
        global default_context
        if not isinstance(context, cda_context):
            self.context = default_context
        else:
            self.context = context
        # Warning!!!

        p1 = base.encode("ascii")
        self.c_base = p1
        p2 = spec.encode("ascii")
        self.c_spec = p2

        self.ret = cda_add_chan(self.context.cid, self.c_base, self.c_spec, 0, dtype, max_nelems,
                                0, <cda_dataref_evproc_t>NULL, NULL)
        cda_check_exception(self.ret)
        self.ref = self.ret

        self.base = base
        self.spec = spec
        self.dtype = dtype
        self.max_nelems = max_nelems
        self.context.chans.append(self.ref)

        # registering callback to check if channel found
        self.add_event(CDA_REF_EVMASK_RSLVSTAT, <void*>evproc_rslvstat, <void*>self, NULL)
        self.notFound = 0


    cdef void snd_data(self, cxdtype_t dtype, int nelems, void* data_p):
        self.ret = cda_snd_ref_data(self.ref, dtype, nelems, data_p)
        cda_check_exception(self.ret)

    cdef void get_data(self, size_t ofs, size_t size, void* buf):
        self.ret = cda_get_ref_data(self.ref, ofs, size, buf)
        cda_check_exception(self.ret)

    cdef void get_stat(self, rflags_t* rflags_p, cx_time_t* timestamp_p):
        self.ret = cda_get_ref_stat(self.ref, rflags_p, timestamp_p)
        cda_check_exception(self.ret)

    cdef void get_dcval(self, double* v_p):
        self.ret = cda_get_dcval(self.ref, v_p)
        cda_check_exception(self.ret)

    cdef void set_dcval(self,double val):
        self.ret = cda_set_dcval(self.ref, val)
        cda_check_exception(self.ret)

    cdef int current_nelems(self):
        return cda_current_nelems_of_ref(self.ref)

    cdef void get_src(self, const char **src_p):
        self.ret = cda_src_of_ref(self.ref, src_p)
        cda_check_exception(self.ret)

    # overriding cda_object method
    cdef void register_event(self, event ev):
        self.ret = cda_add_dataref_evproc(self.ref, ev.evmask, <cda_dataref_evproc_t>(ev.evproc), &ev.ptrs)
        cda_check_exception(self.ret)

    cdef void unregister_event(self, event ev):
        self.ret = cda_del_dataref_evproc(self.ref, ev.evmask, <cda_dataref_evproc_t>(ev.evproc), &ev.ptrs)
        cda_check_exception(self.ret)




# Signal container to bypass inheritance from QObject
# to be encapsulated in Qt channel-like classes
class Signaler(QObject):
    valueChanged = pyqtSignal(object)
    valueMeasured = pyqtSignal(object)

    def __init__(self):
        super(Signaler, self).__init__()


# base class for Qt channel-like classes

cdef class cda_qbase_chan(cda_base_chan):
    #properties
    cdef:
        cx_time_t timestr
        readonly int64 time, prev_time
        int first_cycle
        readonly rflags_t rflags

        object _signaler
        public object valueChanged
        public object valueMeasured

    def __init__(self, context, str base, str spec, cxdtype_t dtype, int max_nelems):
        super(cda_qbase_chan, self).__init__(context, base, spec, dtype, max_nelems)
        self.first_cycle = True # No data callback yet

        # encapsulating Signaler QObject
        self._signaler = Signaler()
        self.valueChanged = self._signaler.valueChanged
        self.valueMeasured = self._signaler.valueMeasured


# user-level channel classes

# scalar double channel
cdef class sdchan(cda_qbase_chan):
    cdef:
        # all general properties defined in base classes
        readonly double val, prev_val, tolerance

    def __init__(self, context, str base, str spec):
        super(sdchan, self).__init__(context, base, spec, CXDTYPE_DOUBLE, 1)
        self.tolerance = 0.0
        self.first_cycle = True
        self.add_event(CDA_REF_EVMASK_UPDATE, <void*>evproc_sdchan, <void*>self, NULL)

    cdef cb(self):
        self.prev_val = self.val
        self.get_dcval(&self.val)
        self.get_stat(&self.rflags, &self.timestr)
        self.prev_time = self.time
        convert_time(&self.timestr, &self.time)
        if math.fabs(self.val - self.prev_val) > self.tolerance or self.first_cycle:
            self.valueChanged.emit(self)
            self.first_cycle = False
        self.valueMeasured.emit(self)

    cpdef setValue(self, double value):
        self.set_dcval(value)


# scalar int32 chan
cdef class sichan(cda_qbase_chan):
    cdef:
        # all general properties defined in base classes
        readonly int32 val, prev_val

    def __init__(self, context, str base, str spec):
        super(sichan, self).__init__(context, base, spec, CXDTYPE_INT32, 1)
        self.first_cycle = True
        self.add_event(CDA_REF_EVMASK_UPDATE, <void*>evproc_sichan, <void*>self, NULL)

    cdef cb(self):
        self.prev_val = self.val
        self.get_data(0, sizeof(self.val), &self.val)
        self.get_stat(&self.rflags, &self.timestr)
        self.prev_time = self.time
        convert_time(&self.timestr, &self.time)
        if self.val != self.prev_val or self.first_cycle:
            self.valueChanged.emit(self)
            self.first_cycle = False
        self.valueMeasured.emit(self)

    cpdef setValue(self, int32 value):
        self.get_data(0, sizeof(self.val), &value)

# general channel (any cx type)
cdef class schan(cda_qbase_chan):
    cdef:
        mixed_data raw_val, raw_perv_val
        size_t itemsize

    def __init__(self, context, str base, str spec, cxdtype_t dtype):
        super(schan, self).__init__(context, base, spec, dtype, 1)
        self.first_cycle = True
        self.add_event(CDA_REF_EVMASK_UPDATE, <void*>evproc_schan, <void*>self, NULL)

    cdef cb(self):
        self.raw_prev_val = self.raw_val
        self.get_data(0, self.itemsize, &self.raw_val)
        self.get_stat(&self.rflags, &self.timestr)
        self.prev_time = self.time
        convert_time(&self.timestr, &self.time)
        #if self.val != self.prev_val or self.first_cycle:
        #    self.valueChanged.emit(self)
        #    self.first_cycle = False
        self.valueMeasured.emit(self)

    def return_value(self):
        if self.dtype == CXDTYPE_INT8:
            return self.raw_val.i8
        if self.dtype == CXDTYPE_INT16:
            return self.raw_val.i16
        if self.dtype == CXDTYPE_INT32:
            return self.raw_val.i32
        if self.dtype == CXDTYPE_INT64:
            return self.raw_val.i64
        if self.dtype == CXDTYPE_UINT8:
            return self.raw_val.u8
        if self.dtype == CXDTYPE_UINT16:
            return self.raw_val.u16
        if self.dtype == CXDTYPE_UINT32:
            return self.raw_val.u32
        if self.dtype == CXDTYPE_UINT64:
            return self.raw_val.u64
        if self.dtype == CXDTYPE_SINGLE:
            return self.raw_val.f32
        if self.dtype == CXDTYPE_DOUBLE:
            return self.raw_val.f64

    val = property(return_value)


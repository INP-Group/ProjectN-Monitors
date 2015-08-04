# Cython wrapper for cxv4 cda
# by Fedor Emanov

#from misc_types cimport *
from monitors.cx4.cython_wrapper.cx cimport *
from cx_common_types cimport *

cdef extern from "cda.h":
    ctypedef CxDataRef_t cda_dataref_t
    ctypedef int cda_context_t

    enum:
        CDA_CTX_R_CYCLE    = 0
        CDA_CTX_EVMASK_CYCLE = 1 << CDA_CTX_R_CYCLE

    enum:
       CDA_REF_R_UPDATE   = 0
       CDA_REF_EVMASK_UPDATE   = 1 << CDA_REF_R_UPDATE
       CDA_REF_R_STATCHG  = 1
       CDA_REF_EVMASK_STATCHG  = 1 << CDA_REF_R_STATCHG
       CDA_REF_R_STRSCHG  = 2
       CDA_REF_EVMASK_STRSCHG  = 1 << CDA_REF_R_STRSCHG
       CDA_REF_R_RDSCHG   = 3
       CDA_REF_EVMASK_RDSCHG   = 1 << CDA_REF_R_RDSCHG
       CDA_REF_R_LOCKSTAT = 4
       CDA_REF_EVMASK_LOCKSTAT = 1 << CDA_REF_R_LOCKSTAT
       CDA_REF_R_RSLVSTAT = 5
       CDA_REF_EVMASK_RSLVSTAT = 1 << CDA_REF_R_RSLVSTAT

    ctypedef enum cda_serverstatus_t:
        #/* Note: the statuses are ordered by decreasing of severity,
        #  so that a "most severe of several" status can be easily chosen */
        CDA_SERVERSTATUS_ERROR        = -1
        CDA_SERVERSTATUS_DISCONNECTED =  0
        CDA_SERVERSTATUS_FROZEN       = +1
        CDA_SERVERSTATUS_ALMOSTREADY  = +2
        CDA_SERVERSTATUS_NORMAL       = +3



    ctypedef void (*cda_context_evproc_t)(int uniq, void *privptr1, cda_context_t cid, int reason, int info_int, void *privptr2)

    ctypedef void (*cda_dataref_evproc_t)(int uniq, void *privptr1, cda_dataref_t ref, int reason, void *info_ptr, void *privptr2)

    cda_context_t cda_new_context(int uniq,   void *privptr1,
                               const char           *defpfx, int   flags,
                               const char           *argv0,
                               int                   evmask,
                               cda_context_evproc_t  evproc,
                               void                 *privptr2)
    int cda_del_context(cda_context_t cid)

    int cda_add_context_evproc(cda_context_t cid,
                               int evmask,
                               cda_context_evproc_t evproc,
                               void *privptr2)

    int cda_del_context_evproc(cda_context_t cid,
                               int evmask,
                               cda_context_evproc_t evproc,
                               void *privptr2)

    #/* Channels management */
    cda_dataref_t  cda_add_chan   (cda_context_t         cid,
                               const char           *base,
                               const char           *spec,
                               int                   flags,
                               cxdtype_t             dtype,
                               int                   max_nelems,
                               int                   evmask,
                               cda_dataref_evproc_t  evproc,
                               void                 *privptr2)

    int            cda_del_chan   (cda_dataref_t ref)

    int            cda_add_dataref_evproc(cda_dataref_t         ref,
                                      int                   evmask,
                                      cda_dataref_evproc_t  evproc,
                                      void                 *privptr2)

    int            cda_del_dataref_evproc(cda_dataref_t         ref,
                                      int                   evmask,
                                      cda_dataref_evproc_t  evproc,
                                      void                 *privptr2)

    int            cda_lock_chans (int count, cda_dataref_t *refs,
                               int operation)

    char *cda_combine_base_and_spec(cda_context_t         cid,
                                const char           *base,
                                const char           *spec,
                                char                 *namebuf,
                                size_t                namebuf_size)

    #/* Simplified channels API */

    cda_dataref_t cda_add_dchan(cda_context_t  cid,
                                const char    *name)

    int cda_get_dcval(cda_dataref_t  ref, double *v_p)

    int cda_set_dcval(cda_dataref_t  ref, double  val)


    #/**/
    int cda_src_of_ref           (cda_dataref_t ref, const char **src_p)
    int cda_dtype_of_ref         (cda_dataref_t ref)
    int cda_nelems_of_ref        (cda_dataref_t ref)
    int cda_current_nelems_of_ref(cda_dataref_t ref)

    int cda_strings_of_ref       (cda_dataref_t  ref,
                                  char    **ident_p,
                                  char    **label_p,
                                  char    **tip_p,
                                  char    **comment_p,
                                  char    **geoinfo_p,
                                  char    **rsrvd6_p,
                                  char    **units_p,
                                  char    **dpyfmt_p)

    int cda_status_srvs_count(cda_context_t  cid)
    cda_serverstatus_t cda_status_of_srv(cda_context_t cid, int nth)
    const char *cda_status_srv_name(cda_context_t cid, int nth)


    #/**********************/

    enum:
        CDA_OPT_NONE     = 0,
        CDA_OPT_IS_W     = 1 << 0,
        CDA_OPT_READONLY = 1 << 1,
        CDA_OPT_DO_EXEC  = 1 << 16,

    enum:
        CDA_PROCESS_ERR          = -1,
        CDA_PROCESS_DONE         =  0,
        CDA_PROCESS_FLAG_BUSY    =  1 << 0,
        CDA_PROCESS_FLAG_REFRESH =  1 << 1,



    int cda_snd_ref_data(cda_dataref_t ref,
                         cxdtype_t dtype, int nelems,
                         void *data)

    int cda_get_ref_data(cda_dataref_t ref,
                         size_t ofs, size_t size, void *buf)

    int cda_get_ref_stat(cda_dataref_t ref,
                         rflags_t *rflags_p, cx_time_t *timestamp_p)

    char *cda_last_err()

#define UNICODE
#define _UNICODE

#include <Python.h>
#include "structmember.h"

#include <windows.h>
#include <shlobj.h>
#include <exdisp.h>
#include <shlwapi.h>
#include <atlbase.h>
#include <atlalloc.h>
#include <stdio.h>
#include <strsafe.h>
#include <cmath>

#include <thread>
#include <chrono>

#define __FILENAME__ (strrchr(__FILE__, '\\') ? strrchr(__FILE__, '\\') + 1 : __FILE__)
#define PY_SET_ERROR_STR(msg, error_type) char __temp_p_s_e_s__[256]; sprintf(__temp_p_s_e_s__, "%s l#%i %s", __FILENAME__, __LINE__, msg); PyErr_SetString(error_type, __temp_p_s_e_s__);
#define PY_SET_OSERROR_STR(msg) PY_SET_ERROR_STR(msg, PyExc_OSError)
#define PY_SET_FOLDER_VIEW_ERROR PY_SET_ERROR_STR("An error occurred while getting desktop items. "\
                                                  "This is expected if there was no timeout after "\
                                                  "the FWF_NOICONS flag was set(Windows bug).",\
                                                  PyExc_LookupError)

#define POS_CHANANGE_PER_N 10000 // 10 milliseconds
#define POSITION_ERROR_VALUE 10 // in pixels

#define MASK_OFF_FWF_SNAPTOGRID 4294967291 // 32 bits XOR 4 (FWF_SNAPTOGRID)

#define TRANSITION_HANDLER_PARAMS_FORMAT "Oiikkllllll"
#define TRANSITION_HANDLER_ARGS_FORMAT "siikkllllll"


typedef enum{
    HANDLER_RC_FINAL_POS = 0x1,
    HANDLER_RC_ALREADY_FINAL = 0x2,
    HANDLER_RC_MORE_ITER = 0x4,
    HANDLER_RC_FATED = 0x8,
} PositionerReturnCodes;

typedef enum {
    HANDLER_CC_NORMAL = 1,
    HANDLER_CC_LAST_CALL
} PositionerCallCodes;

typedef enum {
    ISF_SKIP_DEFAULT_BEFORE_FLAGS = 0x1,
    ISF_SKIP_DEFAULT_AFTER_FLAGS = 0x2,
    ISF_SKIP_DEFAULT_FLAGS = ISF_SKIP_DEFAULT_BEFORE_FLAGS | ISF_SKIP_DEFAULT_AFTER_FLAGS,
    ISF_SKIP_BEFORE_FLAGS = 0x4,
    ISF_SKIP_AFTER_FLAGS = 0x8,
    ISF_SKIP_FLAGS = ISF_SKIP_BEFORE_FLAGS | ISF_SKIP_AFTER_FLAGS,
    ISF_EXACTLY_BEFORE_FLAGS = 0x10,
    ISF_EXACTLY_AFTER_FLAGS = 0x20,
    ISF_EXACTLY_FLAGS = ISF_EXACTLY_AFTER_FLAGS | ISF_EXACTLY_BEFORE_FLAGS,
    ISF_FORBID_NONE_TRANSITION = 0x4000,
} PositionerIconsSetFlags;

typedef struct _IconRepr {
    ITEMIDLIST* PIDL = nullptr;
    CHAR* PIDLRepr = nullptr;
    POINT originPos,
          currentPos,
          targetPos;
    bool isFinalPos = false;
    ~_IconRepr()
    {
        if (PIDL) {
            CoTaskMemFree((LPVOID)PIDL);
        }
        delete[] PIDLRepr;
    }
} IconRepresentation;

int escapeWChars(WCHAR* source, CHAR* dest, int maxLength = MAX_PATH)
{
    // len(source) <= len(dest) * 4
    static char const* const charTable = "0123456789abcdef";

    int charStart = 0, i = 0;
    for (; i < maxLength; i++) {
        if (source[i] == '\0') break;
        charStart = i * 4;

        dest[charStart] = charTable[(source[i] >> 12) & 0xF];
        dest[charStart + 1] = charTable[(source[i] >> 8) & 0xF];
        dest[charStart + 2] = charTable[(source[i] >> 4) & 0xF];
        dest[charStart + 3] = charTable[(source[i]) & 0xF];
    }
    dest[i * 4] = '\0';

    return i;
}

void PIDLAsHex(ITEMIDLIST* spidl, UINT cb, CHAR* repr)
{
    BYTE* pb = reinterpret_cast<BYTE*>
        (static_cast<PIDLIST_ABSOLUTE>(spidl));

    for (long long i = 0; i < cb; i++) {
        CHAR szHex[3];
        StringCchPrintfA(szHex, ARRAYSIZE(szHex),
            "%02X", pb[i]);
        strcpy_s(repr + i * 2, 3, szHex);
    }
}

void PrintPyObj(PyObject* obj)
{
    if (obj != NULL) {
        PyObject* repr = PyObject_Repr(obj);
        PyObject* str = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
        const char* bytes = PyBytes_AS_STRING(str);

        printf("REPR: %s\n", bytes);

        Py_XDECREF(repr);
        Py_XDECREF(str);
    }
    else {
        printf("REPR: NULL\n");
    }
}

/* Set all bits after first 1 to 1*/
unsigned long buildTrueMask(unsigned long flags)
{
    return (static_cast <unsigned long long>(1)
            << static_cast<unsigned short>(log2(flags)) + 1)
            - 1;
}

bool FindDesktopFolderView(REFIID riid, void** ppv)
{
    CComPtr<IShellWindows> spShellWindows;
    CComPtr<IShellBrowser> spBrowser;
    CComPtr<IShellView> spView;
    CComPtr<IDispatch> spdisp;
    CComVariant vtLoc(CSIDL_DESKTOP);
    CComVariant vtEmpty;
    long lhwnd;

    if (!SUCCEEDED(spShellWindows.CoCreateInstance(CLSID_ShellWindows))) {
        PY_SET_OSERROR_STR("CoCreateInstance error");
        return false;
    }

    if (!SUCCEEDED(spShellWindows->FindWindowSW(&vtLoc, &vtEmpty, SWC_DESKTOP,
                                                &lhwnd, SWFO_NEEDDISPATCH, &spdisp))) {
        PY_SET_OSERROR_STR("FindWindowSW error");
        return false;
    }

    if (!SUCCEEDED(CComQIPtr<IServiceProvider>(spdisp)->QueryService(SID_STopLevelBrowser,
                                                                     IID_PPV_ARGS(&spBrowser)))) {
        PY_SET_OSERROR_STR("IServiceProvider error");
        return false;
    }

    if (!SUCCEEDED(spBrowser->QueryActiveShellView(&spView))) {
        PY_SET_OSERROR_STR("IShellBrowser error");
        return false;
    }

    if (!SUCCEEDED(spView->QueryInterface(riid, ppv))) {
        PY_SET_OSERROR_STR("IShellView error");
        return false;
    }
    
    return true;
}

/*
 * Switch Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */

static bool
SwitchDesktopFlags(IFolderView2* spView, DWORD flags)
{
    DWORD currentFolderFlags;

    if (!SUCCEEDED(spView->GetCurrentFolderFlags(&currentFolderFlags)) ||
        !SUCCEEDED(spView->SetCurrentFolderFlags(flags, currentFolderFlags ^ flags))) {
        return false;
    }
    return true;
}

static unsigned long
GetDesktopFlags(IFolderView2* spView)
{
    DWORD currentFolderFlags;

    if (SUCCEEDED(spView->GetCurrentFolderFlags(&currentFolderFlags))) {
        return currentFolderFlags;
    }
    PY_SET_ERROR_STR("Failed to get desktop flags", PyExc_OSError);
    return 0; // Check for error after the call
}

static bool
ExactlySetDesktopFlags(IFolderView2* spView, DWORD flags)
{
    if (!SUCCEEDED(spView->SetCurrentFolderFlags(buildTrueMask(flags), flags))) {
        return false;
    }
    return true;
}

static bool
SetDesktopFlags(IFolderView2* spView, DWORD flags)
{
    if (!SUCCEEDED(spView->SetCurrentFolderFlags(flags, 0xffffffff))) {
        return false;
    }
    return true;
}

static bool
UnsetDesktopFlags(IFolderView2* spView, DWORD flags)
{
    if (!SUCCEEDED(spView->SetCurrentFolderFlags(flags, 0))) {
        return false;
    }
    return true;
}

/* Wrapper for global 'instance' of IFolderView(2)*/
typedef struct {
    PyObject_HEAD

    CComPtr<IFolderView2> spView = NULL;

    IFolderView2* getView(bool renew = false)
    {
        if (spView.p == NULL || renew) {
            spView.Release();
            if (!FindDesktopFolderView(IID_PPV_ARGS(&spView))) {
                return NULL;
            }
        }

        if (haveView()) {
            return &*spView;
        }
        else {
            PY_SET_OSERROR_STR("Unexpected behavior")
            return NULL;
        }
    }

    bool haveView()
    {
        return spView.p != NULL;
    }
} PCPFolderViewObject;

static int
pcp_fv_to_bool(PCPFolderViewObject* self)
{
    return self->haveView() ? 1 : 0;
}

static void
PCPFolderView_dealloc(PCPFolderViewObject* self)
{
    self->spView.Release();
}

static PyNumberMethods pcp_folder_view_as_number = {
    0,                          /* nb_add */
    0,                          /* nb_subtract */
    0,                          /* nb_multiply */
    0,                          /* nb_remainder */
    0,                          /* nb_divmod */
    0,                          /* nb_power */
    0,                          /* nb_negative */
    0,                          /* nb_positive */
    0,                          /* nb_absolute */
    (inquiry)pcp_fv_to_bool,    /* nb_bool */
    0,                          /* nb_invert */
    0,                          /* nb_lshift */
    0,                          /* nb_rshift */
    0,                          /* nb_and */
    0,                          /* nb_xor */
    0,                          /* nb_or */
    0,                          /* nb_int */
    0,                          /* nb_reserved */
    0,                          /* nb_float */
    0,                          /* nb_inplace_add */
    0,                          /* nb_inplace_subtract */
    0,                          /* nb_inplace_multiply */
    0,                          /* nb_inplace_remainder */
    0,                          /* nb_inplace_power */
    0,                          /* nb_inplace_lshift */
    0,                          /* nb_inplace_rshift */
    0,                          /* nb_inplace_and */
    0,                          /* nb_inplace_xor */
    0,                          /* nb_inplace_or */
    0,                          /* nb_floor_divide */
    0,                          /* nb_true_divide */
    0,                          /* nb_inplace_floor_divide */
    0,                          /* nb_inplace_true_divide */
    0,                          /* nb_index */
};

static PyTypeObject PCPFolderViewType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "positioner_c_part.PCPFolderViewObject",   /*tp_name*/
    sizeof(PCPFolderViewObject),               /*tp_basicsize*/
    0,                                         /*tp_itemsize*/
    (destructor)PCPFolderView_dealloc,         /*tp_dealloc*/
    0,                                         /*tp_print*/
    0,                                         /*tp_getattr*/
    0,                                         /*tp_setattr*/
    0,                                         /*tp_compare*/
    0,                                         /*tp_repr*/
    &pcp_folder_view_as_number,                /*tp_as_number*/
    0,                                         /*tp_as_sequence*/
    0,                                         /*tp_as_mapping*/
    0,                                         /*tp_hash */
    0,                                         /*tp_call*/
    0,                                         /*tp_str*/
    0,                                         /*tp_getattro*/
    0,                                         /*tp_setattro*/
    0,                                         /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,  /*tp_flags*/
    PyDoc_STR("Handles smartptr to "
              "IFolderView."),                 /* tp_doc */
    0,                                         /* tp_traverse */
    0,                                         /* tp_clear */
    0,                                         /* tp_richcompare */
    0,                                         /* tp_weaklistoffset */
    0,                                         /* tp_iter */
    0,                                         /* tp_iternext */
    0,                                         /* tp_methods */
    0,                                         /* tp_members */
    0,                                         /* tp_getset */
    0,                                         /* tp_base */
    0,                                         /* tp_dict */
    0,                                         /* tp_descr_get */
    0,                                         /* tp_descr_set */
    0,                                         /* tp_dictoffset */
    0,                                         /* tp_init */
    0,                                         /* tp_alloc */
    PyType_GenericNew,                         /* tp_new */
};

typedef struct {
    PyObject_HEAD
    unsigned long allotted_time; // microseconds
    unsigned short steps_count; // auxiliary variable to calculate a smoother transition
    PyObject* transition_name;
    PyObject* transition_description;
    PyObject* data; // auxiliary dict for saving info between iterations of position change 
} TransitionHandlerObject;

static PyObject*
TransitionHandler_str(TransitionHandlerObject* self)
{
    return PyUnicode_FromFormat("<%s name=\"%U\" descr=\"%U\" allotted_time=%lu>",
                                Py_TYPE(self)->tp_name, self->transition_name,
                                self->transition_description, self->allotted_time);
}

static void
TransitionHandler_dealloc(TransitionHandlerObject* self)
{
    Py_XDECREF(self->transition_name);
    Py_XDECREF(self->transition_description);
    Py_XDECREF(self->data);
    Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
TransitionHandler_init(TransitionHandlerObject* self, PyObject* args, PyObject* kwds)
{
    PyObject* name = NULL, * tmp;
    unsigned long allotted_time = 500000;

    static char* kwlist[] = { "name", "allotted_time", NULL };
    if (!PyArg_ParseTupleAndKeywords(args, kwds, "Uk", kwlist,
                                     &name, &allotted_time)) {
        return -1;
    }

    self->allotted_time = allotted_time;

    if (name) {
        tmp = self->transition_name;
        Py_INCREF(name);
        self->transition_name = name;
        Py_XDECREF(tmp);
    }

    self->data = PyDict_New();
    self->steps_count = allotted_time / POS_CHANANGE_PER_N;

    tmp = self->transition_description;
    self->transition_description = PyUnicode_FromString("Base transition type. Easy-out");
    Py_XDECREF(tmp);

    return 0;
}


/*
 * Life cycle callback. Called before the start of the position change cycle.
 */
PyDoc_STRVAR(positioner_c_part_handle_init_doc, 
"handle_init(self, icons_data: Dict[str, Dict[str, Any]]\n"
"            allotted_time: int)\n\n"
"Called before the start of the position change cycle.\n"
" - `allotted_time` in microseconds(unsigned long)\n"
" - `icons_data` copy of the actual icons_data dict passed"
" to `set_icons_data` without REFCOUNT increase");

static PyObject*
positioner_c_part_handle_init(TransitionHandlerObject* self, PyObject* args, PyObject* kwargs)
{
    //PyObject* icons_data = NULL;
    //
    //
    //static char* keywords[] = { "icons_data", NULL };
    //if (!PyArg_ParseTupleAndKeywords(args, kwargs, "O", keywords, &icons_data)) {
    //    return NULL;
    //}

    Py_RETURN_NONE;
}

/*
 * Life cycle callback. Called after the end of the position change cycle.
 */
PyDoc_STRVAR(positioner_c_part_handle_final_doc,
"handle_final(self)\n\n"
"Called after the end of the position change cycle.");

static PyObject*
positioner_c_part_handle_final(TransitionHandlerObject* self, char* Py_UNUSED(ignored))
{
    Py_RETURN_NONE;
}

/*
 * Life cycle callback. Called after the end of the position change cycle.
 */
PyDoc_STRVAR(positioner_c_part_handle_between_iter_doc,
"handle_between_iter(self, elapsed_time: int,\n"
"                    allotted_time: int) -> int\n\n"
"Called after each position change cycle.\n"
"`elapsed_time` and `allotted_time` -> microseconds"
"Must return the time in microseconds for which"
"execution will be stopped before the next iteration");

static PyObject*
positioner_c_part_handle_between_iter(TransitionHandlerObject* self, PyObject* args, PyObject* kwargs)
{
    //unsigned long elapsed_time = 0, allotted_time = 0;
    //
    //
    //static char* keywords[] = { "elapsed_time", "allotted_time", NULL };
    //if (!PyArg_ParseTupleAndKeywords(args, kwargs, "kk", keywords, &elapsed_time, &allotted_time)) {
    //    return NULL;
    //}

    return PyLong_FromLong(self->allotted_time / self->steps_count);
}

/*
 * Life cycle callback. Called for each icon to calculate position change
 */
PyDoc_STRVAR(positioner_c_part_handle_position_doc,
"handle_position(self, icon_pidl: str,\n"
"                call_flag: int, iteration_num: int,\n"
"                elapsed_time: int, allotted_time: int,\n"
"                origin_x: int, origin_y: int,\n"
"                current_x: int, current_y: int,\n"
"                target_x: int, target_y: int)"
" -> Tuple[int, int, int]\n\n"

"Called at each iteration for each icon"
"to calculate the position change.\n"
"`elapsed_time` and `alloted_time`"
" -> time in microseconds\n"
"Param `call_flag` determine the stage of"
"processing the change of positions:\n"
" - HANDLER_CC_NORMAL normal call, without limits\n"
" - HANDLER_CC_LAST_CALL indicates that this is"
"the last call, regardless of the flag returned\n\n"
"The function must return one of the flags:\n"
" - HANDLER_RC_FINAL_POS\n"
" - HANDLER_RC_MORE_ITER\n"
" - HANDLER_RC_ALREADY_FINAL\n"
" - HANDLER_RC_FATED\n\n"
"If a smooth position change is needed,"
"the function should return `HANDLER_RC_MORE_ITER`,"
"after which the handler will be called for"
"the current icon at the next iteration.\n"
"If the calculated new position is the same as the "
"current position, the callback may return"
" `HANDLER_RC_ALREADY_FINAL` flag "
" to avoid an unnecessary change position call.\n"
"If the position of the current icon is final"
" - the function should return `HANDLER_RC_FINAL_POS`");

static PyObject*
positioner_c_part_handle_position(TransitionHandlerObject* self, PyObject* args, PyObject* kwargs)
{
    PyObject* icon_pidl = NULL;
    int call_flag, iteration_num;
    unsigned long elapsed_time, allotted_time;
    long origin_x, origin_y,
         current_x, current_y,
         target_x, target_y;

    static char* keywords[] = { "icon_pidl", "call_flag",
                                "iteration_num",
                                "elapsed_time", "allotted_time",
                                "origin_x", "origin_y",
                                "current_x", "current_y",
                                "target_x", "target_y", NULL };
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, TRANSITION_HANDLER_PARAMS_FORMAT,
                                     keywords, &icon_pidl,
                                     &call_flag, &iteration_num,
                                     &elapsed_time, &allotted_time,
                                     &origin_x, &origin_y,
                                     &current_x, &current_y,
                                     &target_x, &target_y)) {
        return NULL;
    }

    if (call_flag == HANDLER_CC_LAST_CALL) {
        return Py_BuildValue("(ill)", HANDLER_RC_FATED,
                             target_x, target_y);
    }

    long delta_x = target_x - current_x,
         delta_y = target_y - current_y,
         current_step = elapsed_time / (allotted_time / self->steps_count) + 1;

    if (current_step < self->steps_count) {
        PyObject* temp = NULL;
        long new_x = current_x + delta_x * current_step / self->steps_count,
             new_y = current_y + delta_y * current_step / self->steps_count;

        if (abs(new_x - target_x) < POSITION_ERROR_VALUE &&
            abs(new_y - target_y) < POSITION_ERROR_VALUE) {

            temp = Py_BuildValue("(ill)", HANDLER_RC_FINAL_POS,
                                 target_x, target_y);
        }
        else {
            temp = Py_BuildValue("(ill)", HANDLER_RC_MORE_ITER,
                                 new_x, new_y);
        }

        return temp;
    }
    else {
        return Py_BuildValue("(ill)", HANDLER_RC_FINAL_POS,
                             target_x, target_y);
    }
}

static PyMethodDef TransitionHandle_methods[] = {
    {"handle_init", (PyCFunction)positioner_c_part_handle_init, METH_VARARGS | METH_KEYWORDS,
     positioner_c_part_handle_init_doc
    },
    {"handle_position", (PyCFunction)positioner_c_part_handle_position, METH_VARARGS | METH_KEYWORDS,
     positioner_c_part_handle_position_doc
    },
    {"handle_between_iter", (PyCFunction)positioner_c_part_handle_between_iter, METH_VARARGS | METH_KEYWORDS,
     positioner_c_part_handle_between_iter_doc
    },
    {"handle_final", (PyCFunction)positioner_c_part_handle_final, METH_NOARGS,
     positioner_c_part_handle_final_doc
    },
    {NULL}
};

static PyObject*
TransitionHandler_getname(TransitionHandlerObject* self, void* closure)
{
    Py_INCREF(self->transition_name);
    return self->transition_name;
}

static int
TransitionHandler_setname(TransitionHandlerObject* self, PyObject* value, void* closure)
{
    PyObject* tmp;
    if (value == NULL) {
        PY_SET_ERROR_STR("Cannot delete the `transition_name` attribute", PyExc_TypeError);
        return -1;
    }
    if (!PyUnicode_Check(value)) {
        PY_SET_ERROR_STR("The `transition_name` attribute value must be a string", PyExc_TypeError);
        return -1;
    }
    tmp = self->transition_name;
    Py_INCREF(value);
    self->transition_name = value;
    Py_DECREF(tmp);
    return 0;
}

static PyObject*
TransitionHandler_getdescription(TransitionHandlerObject* self, void* closure)
{
    Py_INCREF(self->transition_description);
    return self->transition_description;
}

static int
TransitionHandler_setdescription(TransitionHandlerObject* self, PyObject* value, void* closure)
{
    PyObject* tmp;
    if (value == NULL) {
        PY_SET_ERROR_STR("Cannot delete the `transition_description` attribute", PyExc_TypeError);
        return -1;
    }
    if (!PyUnicode_Check(value)) {
        PY_SET_ERROR_STR("The `transition_description` attribute value must be a string", PyExc_TypeError);
        return -1;
    }
    tmp = self->transition_description;
    Py_INCREF(value);
    self->transition_description = value;
    Py_DECREF(tmp);
    return 0;
}

static PyObject*
TransitionHandler_getallotted_time(TransitionHandlerObject* self, void* closure)
{
    return PyLong_FromUnsignedLong(self->allotted_time);
}

static int
TransitionHandler_setallotted_time(TransitionHandlerObject* self, PyObject* value, void* closure)
{
    if (value == NULL) {
        PY_SET_ERROR_STR("Cannot delete the `allotted_time` attribute", PyExc_TypeError);
        return -1;
    }
    if (!PyLong_Check(value)) {
        PY_SET_ERROR_STR("The `allotted_time` attribute value must be int", PyExc_TypeError);
        return -1;
    }

    unsigned long tmp = PyLong_AsUnsignedLong(value);

    if (PyErr_Occurred()) {
        PyErr_Clear();
        PY_SET_ERROR_STR("The `allotted_time` attribute value must be unsigned long "
                         "(in range from 0 to 4294967295)", PyExc_ValueError);
        return -1;
    }

    self->allotted_time = tmp;

    return 0;
}

static PyGetSetDef TransitionHandler_getsetters[] = {
    {"name", (getter)TransitionHandler_getname,
     (setter)TransitionHandler_setname,"transition name", NULL},
    {"description", (getter)TransitionHandler_getdescription,
     (setter)TransitionHandler_setdescription, "transition description", NULL},
    {"allotted_time", (getter)TransitionHandler_getallotted_time,
     (setter)TransitionHandler_setallotted_time, "allotted time for transition", NULL},
    {NULL}
};

static PyMemberDef TransitionHandler_members[] = {
    {"data", T_OBJECT_EX, offsetof(TransitionHandlerObject, data), 0,
     "auxiliary dict for saving info between iterations of position change"},
    {"steps_count", T_USHORT, offsetof(TransitionHandlerObject, steps_count), 0,
     "auxiliary variable to calculate a smoother transition"},
    {NULL}
};

static PyTypeObject TransitionHandlerType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "positioner_c_part.TransitionHandler",     /*tp_name*/
    sizeof(TransitionHandlerObject),           /*tp_basicsize*/
    0,                                         /*tp_itemsize*/
    (destructor)TransitionHandler_dealloc,     /*tp_dealloc*/
    0,                                         /*tp_print*/
    0,                                         /*tp_getattr*/
    0,                                         /*tp_setattr*/
    0,                                         /*tp_compare*/
    (reprfunc)TransitionHandler_str,           /*tp_repr*/
    0,                                         /*tp_as_number*/
    0,                                         /*tp_as_sequence*/
    0,                                         /*tp_as_mapping*/
    0,                                         /*tp_hash */
    0,                                         /*tp_call*/
    0,                                         /*tp_str*/
    0,                                         /*tp_getattro*/
    0,                                         /*tp_setattro*/
    0,                                         /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,  /*tp_flags*/
    PyDoc_STR("Combines methods for handling "
              "icon position changes."),       /* tp_doc */
    0,                                         /* tp_traverse */
    0,                                         /* tp_clear */
    0,                                         /* tp_richcompare */
    0,                                         /* tp_weaklistoffset */
    0,                                         /* tp_iter */
    0,                                         /* tp_iternext */
    TransitionHandle_methods,                  /* tp_methods */
    TransitionHandler_members,                 /* tp_members */
    TransitionHandler_getsetters,              /* tp_getset */
    0,                                         /* tp_base */
    0,                                         /* tp_dict */
    0,                                         /* tp_descr_get */
    0,                                         /* tp_descr_set */
    0,                                         /* tp_dictoffset */
    (initproc)TransitionHandler_init,          /* tp_init */
    0,                                         /* tp_alloc */
    PyType_GenericNew,                         /* tp_new */
};

/*
 * Switch Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */
PyDoc_STRVAR(positioner_c_part_switch_desktop_flags_doc,
"switch_desktop_flags(self, flags: int) -> bool\n\n"
"Switch Desktop folder flags, like:\n",
" - Hide\\show icons\n",
" - On\\Off grid alignment\n",
"More: https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags \n",
"`flags` is unsigned long(32 bit)."
"Represent combination of folder flags,"
"which must be switched.\n"
"Returns True on success");

static PyObject*
positioner_c_part_switch_desktop_flags(PyObject* self, PyObject* _flags)
{
    unsigned long flags = PyLong_AsUnsignedLong(_flags);

    if (PyErr_Occurred()) {
        return NULL;
    }

    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    IFolderView2* folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        // The error is already set
        return NULL;
    }
    bool result = SwitchDesktopFlags(folderView, flags);

    if (!result) {
        PY_SET_OSERROR_STR("SwitchDesktopFlags error");
        return NULL;
    }

    PyObject* py_result = PyBool_FromLong(result);

    return py_result;
}

/*
 * Set Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */
PyDoc_STRVAR(positioner_c_part_exactly_set_desktop_flags_doc,
"exactly_set_desktop_flags(self, flags: int) -> bool\n\n"
"Set Desktop folder flags, exactly as they passed.\n",
"Use with CAUTION!\n\n",
"More: https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags \n",
"`flags` is unsigned long(32 bit)."
"Represent combination of folder flags.\n"
"Returns True on success");

static PyObject*
positioner_c_part_exactly_set_desktop_flags(PyObject* self, PyObject* _flags)
{
    unsigned long flags = PyLong_AsUnsignedLong(_flags);

    if (PyErr_Occurred()) {
        return NULL;
    }

    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    IFolderView2* folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        // The error is already set
        return NULL;
    }
    bool result = ExactlySetDesktopFlags(folderView, flags);

    if (!result) {
        PY_SET_OSERROR_STR("ExactlySetDesktopFlags error");
        return NULL;
    }

    PyObject* py_result = PyBool_FromLong(result);

    return py_result;
}

/*
 * Set(enable) Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */
PyDoc_STRVAR(positioner_c_part_set_desktop_flags_doc,
"set_desktop_flags(self, flags: int) -> bool\n\n"
"Enable Desktop folder flags, like:\n",
" - Show icons\n",
" - Activate grid alignment\n",
"More: https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags \n",
"`flags` is unsigned long(32 bit)."
"Represent combination of folder flags,"
"which must be setted.\n"
"Returns True on success");

static PyObject*
positioner_c_part_set_desktop_flags(PyObject* self, PyObject* _flags)
{
    unsigned long flags = PyLong_AsUnsignedLong(_flags);

    if (PyErr_Occurred()) {
        return NULL;
    }

    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    IFolderView2* folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        PY_SET_OSERROR_STR("getView error")
        return NULL;
    }
    bool result = SetDesktopFlags(folderView, flags);

    if (!result) {
        PY_SET_OSERROR_STR("SetDesktopFlags error");
        return NULL;
    }

    PyObject* py_result = PyBool_FromLong(result);

    return py_result;
}

/*
 * Set(enable) Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */
PyDoc_STRVAR(positioner_c_part_unset_desktop_flags_doc,
"unset_desktop_flags(self, flags: int) -> bool\n\n"
"Disable Desktop folder flags, like:\n",
" - Hide icons\n",
" - Deactivate grid alignment\n",
"More: https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags \n",
"`flags` is unsigned long(32 bit)."
"Represent combination of folder flags,"
"which must be unsetted.\n"
"Returns True on success");

static PyObject*
positioner_c_part_unset_desktop_flags(PyObject* self, PyObject* _flags)
{
    unsigned long flags = PyLong_AsUnsignedLong(_flags);

    if (PyErr_Occurred()) {
        return NULL;
    }

    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    IFolderView2* folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        // The error is already set
        return NULL;
    }

    bool result = UnsetDesktopFlags(folderView, flags);

    if (!result) {
        PY_SET_OSERROR_STR("UnsetDesktopFlags error");
        return NULL;
    }

    PyObject* py_result = PyBool_FromLong(result);

    return py_result;
}

/*
 * Get current Desktop folder flags.
 * Available flags:
 *  - https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags
 */

PyDoc_STRVAR(positioner_c_part_get_desktop_flags_doc,
"get_desktop_flags(self) -> int\n\n"
"Returns active flags as "
"unsigned long(32 bit)\n",
"More about flags: "
"https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/ne-shobjidl_core-folderflags \n",
"Raises `OSError` on failure");

static PyObject*
positioner_c_part_get_desktop_flags(PyObject* self, char* Py_UNUSED(ignored))
{
    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    IFolderView2* folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        // The error is already set
        return NULL;
    }

    PyObject* py_result = PyLong_FromUnsignedLong(GetDesktopFlags(folderView));

    return !PyErr_Occurred() ? py_result : NULL;
}

/*
 * Set desktop icons position
 */
PyDoc_STRVAR(positioner_c_part_set_icons_data_doc,
"set_icons_data(self, icons_data: Sequence[Dict[str, Dict]],\n"
"               *,\n"
"               transition_handler: Optional[TransitionHandler],\n"
"               flags: int, before_desktop_flags: int,\n"
"               after_desktop_flags: int) -> Sequence[str]\n\n"
"Sets the position of the icons whose IDs were passed"
"via `icons_data`, the process of moving is implemented in "
"`transition_handler` - an object of type TransitionHandler(Type). "
"`flags` pass some options to this function behavior.\n"
"`before_desktop_flags` sets before process start."
"`after_desktop_flags` sets after process end.");

static PyObject*
positioner_c_part_set_icons_data(PyObject* self, PyObject* args, PyObject* kwargs)
{
    PyObject* icons_data = NULL, * transition_handler = NULL, * temp_obj;
    unsigned long flags = ISF_EXACTLY_FLAGS,
                  beforeDesktopFlags = 0, afterDesktopFlags = 0,
                  elapsedTime, sleepTime, timeDelta, allottedTime = 1000000;

    static char* keywords[] = { "icons_data", "transition_handler", "flags",
                                "before_desktop_flags", "after_desktop_flags", NULL };
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "O|$Okkk", keywords, &icons_data, &transition_handler,
                                     &flags, &beforeDesktopFlags, &afterDesktopFlags)) {
        return NULL;
    }

    if (!PyObject_IsInstance(icons_data, (PyObject*)&PyDict_Type)) {
        PY_SET_ERROR_STR("`icons_data` must be of type <dict>", PyExc_TypeError);
        return NULL;
    }

    if (transition_handler == NULL && !(flags & ISF_FORBID_NONE_TRANSITION)) {
        temp_obj = Py_BuildValue("(sk)", "Auto Transition", allottedTime);
        transition_handler = PyObject_CallObject((PyObject*)&TransitionHandlerType, temp_obj);
        Py_DECREF(temp_obj);
    }
    else if (transition_handler == NULL || !PyObject_IsInstance(transition_handler, (PyObject*)&TransitionHandlerType)) {
        PY_SET_ERROR_STR("`transition_handler` must be of type <TransitionHandler>", PyExc_TypeError);
        return NULL;
    }
    else {
        Py_INCREF(transition_handler);
    }

    temp_obj = PyObject_GetAttrString(transition_handler, "allotted_time");
    if (!temp_obj) {
        PY_SET_ERROR_STR("<TransitionHandler> must have an `allotted_time` member", PyExc_AttributeError);
        return NULL;
    }

    allottedTime = PyLong_AsUnsignedLong(temp_obj);
    Py_DECREF(temp_obj);

    if (PyErr_Occurred()) {
        PY_SET_ERROR_STR("<TransitionHandler>.`allotted_time` must be of type <int>", PyExc_TypeError);
        return NULL;
    }


    int iterationNum = 0, currentIconIndex = 0,
        uncompletedIcons, returnCode;
    bool lastIteration = false, errorOccurred = false;

    IFolderView2* folderView;
    CComPtr<IEnumIDList> spEnum;
    DWORD currentFolderFlags;
    size_t targetIconsCount = PyDict_Size(icons_data);

    /* `IconsStorage` and `targetIconsID` storing same pointer to `PIDL` */
    LPCITEMIDLIST* targetIconsID = new LPCITEMIDLIST[targetIconsCount];
    POINT* calculatedIconsPosition = new POINT[targetIconsCount];
    IconRepresentation* iconsStorage = new IconRepresentation[targetIconsCount],
                      * currentIcon;
    std::chrono::time_point<std::chrono::steady_clock> iterationsBegin,
                                                       iterationNow,
                                                       currentIterationBegin;

    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));

    folderView = folder_view->getView();
    Py_DECREF(folder_view);
    if (folderView == NULL) {
        PY_SET_OSERROR_STR("Unknown Error");
        return NULL;
    }

    PyObject* missed_icons = PyList_New(0);
    PyObject* current_icon = NULL;

    if (folderView->Items(SVGIO_ALLVIEW, IID_PPV_ARGS(&spEnum)) != S_OK) {
        PY_SET_FOLDER_VIEW_ERROR;
        return NULL;
    }

    if (beforeDesktopFlags != 0 && !(flags & ISF_SKIP_BEFORE_FLAGS)) {
        if (flags & ISF_EXACTLY_BEFORE_FLAGS ? !ExactlySetDesktopFlags(folderView, beforeDesktopFlags)
                                             : !SetDesktopFlags(folderView, beforeDesktopFlags)) {
            PY_SET_ERROR_STR("Error while setting before_desktop_flags."
                             " Maybe `before_desktop_flags` is incorrect?",
                             PyExc_ValueError);
            return NULL;
        }
    }

    if (!(flags & ISF_SKIP_DEFAULT_BEFORE_FLAGS)) {
        folderView->GetCurrentFolderFlags(&currentFolderFlags);

        folderView->SetCurrentFolderFlags(FWF_SNAPTOGRID, currentFolderFlags & MASK_OFF_FWF_SNAPTOGRID);
    }

    temp_obj = PyObject_CallMethod(transition_handler, "handle_init",
                                   "O", icons_data);
    Py_XDECREF(temp_obj);
    if (temp_obj == NULL) {
        PY_SET_ERROR_STR("Error occurred whil executing `handle_init` ", PyExc_RuntimeError);
        errorOccurred = true;
    }

    if (!errorOccurred) {
        /* Collect PIDLs of icons */
        for (ITEMIDLIST* spidl;
            spEnum->Next(1, &spidl, nullptr) == S_OK;
            currentIconIndex++) {

            POINT currentPP;
            UINT spidl_cb = ILGetSize(spidl);
            CHAR* idRepr = new CHAR[static_cast<long long>(spidl_cb) * 2 + 1];

            folderView->GetItemPosition(spidl, &currentPP);
            PIDLAsHex(spidl, spidl_cb, idRepr);

            current_icon = PyDict_GetItemString(icons_data, idRepr);

            if (current_icon == NULL) {
                PyObject* tempIdRepr = Py_BuildValue("s", idRepr);
                PyList_Append(missed_icons, tempIdRepr);
                Py_DECREF(tempIdRepr);
                currentIconIndex--;
                delete[] idRepr;
                CoTaskMemFree(spidl);
            }
            else {
                PyObject* target_x_obj = PyDict_GetItemString(current_icon, "x"),
                    * target_y_obj = PyDict_GetItemString(current_icon, "y");

                if (target_x_obj == NULL || target_y_obj == NULL) {
                    PY_SET_ERROR_STR("`icons_data` doesn`t have `x` or\\and `y` fields", PyExc_ValueError);

                    errorOccurred = true;
                    break;
                }

                long targetX = PyLong_AsLong(target_x_obj),
                    targetY = PyLong_AsLong(target_y_obj);

                if (PyErr_Occurred()) {
                    PY_SET_ERROR_STR(" `x` and `y` fields must be <int>", PyExc_ValueError);

                    errorOccurred = true;
                    break;
                }

                iconsStorage[currentIconIndex].PIDL = spidl;
                iconsStorage[currentIconIndex].PIDLRepr = idRepr;
                iconsStorage[currentIconIndex].originPos = currentPP;
                iconsStorage[currentIconIndex].currentPos = currentPP;
                iconsStorage[currentIconIndex].targetPos = { targetX, targetY };
            }
        }
    }
    

    targetIconsCount = currentIconIndex;

    iterationsBegin = std::chrono::steady_clock::now();

    /* Change of position can be calculated gradually (in several iterations) */
    while(!errorOccurred) {

        iterationNum++;
        uncompletedIcons = 0;
        currentIterationBegin = std::chrono::steady_clock::now();

        for (currentIconIndex = 0;
             currentIconIndex < targetIconsCount;
             currentIconIndex++) {
            
            currentIcon = &iconsStorage[currentIconIndex];

            if (currentIcon->isFinalPos) {
                continue;
            }

            iterationNow = std::chrono::steady_clock::now();
            elapsedTime = std::chrono::duration_cast<std::chrono::microseconds>
                                       (iterationNow - iterationsBegin).count();

            PyObject* handler_res = PyObject_CallMethod(transition_handler, "handle_position",
                                                        TRANSITION_HANDLER_ARGS_FORMAT,
                                                        currentIcon->PIDLRepr,
                                                        lastIteration ? HANDLER_CC_LAST_CALL :
                                                                        HANDLER_CC_NORMAL,
                                                        iterationNum,
                                                        elapsedTime,
                                                        allottedTime,
                                                        currentIcon->originPos.x,
                                                        currentIcon->originPos.y,
                                                        currentIcon->currentPos.x,
                                                        currentIcon->currentPos.y,
                                                        currentIcon->targetPos.x,
                                                        currentIcon->targetPos.y);

            if (handler_res == NULL || !PyTuple_Check(handler_res)) {
                errorOccurred = true;
                break;
            }

            PyArg_ParseTuple(handler_res, "ill", &returnCode,
                             &currentIcon->currentPos.x, &currentIcon->currentPos.y);
            Py_XDECREF(handler_res);


            if (returnCode & (HANDLER_RC_FINAL_POS | HANDLER_RC_ALREADY_FINAL)) {
                currentIcon->isFinalPos = true;
            }
            calculatedIconsPosition[uncompletedIcons] = currentIcon->currentPos;
            targetIconsID[uncompletedIcons++] = currentIcon->PIDL;
        } /* end of position change iteration */

        if (errorOccurred || uncompletedIcons == 0) {
            break;
        }

        folderView->SelectAndPositionItems(uncompletedIcons,
                                           targetIconsID,
                                           calculatedIconsPosition,
                                           SVSI_POSITIONITEM);

        if (lastIteration) {
            break;
        }

        iterationNow = std::chrono::steady_clock::now();
        if (iterationsBegin + std::chrono::microseconds(allottedTime) <
            iterationNow) {
            lastIteration = true;
        }

        PyObject* time_for_sleep = PyObject_CallMethod(transition_handler, "handle_between_iter",
                                                       "kk", &elapsedTime, &allottedTime);
        
        if (!PyLong_Check(time_for_sleep)) {
            PY_SET_ERROR_STR("`handle_between_iter` must return only <int> type", PyExc_ValueError);
            Py_XDECREF(time_for_sleep);

            errorOccurred = true;
            break;
        }

        sleepTime = PyLong_AsUnsignedLong(time_for_sleep);
        Py_DECREF(time_for_sleep);
        timeDelta = std::chrono::duration_cast<std::chrono::microseconds>
                    (std::chrono::steady_clock::now() - currentIterationBegin).count();
        if (timeDelta < sleepTime) {
            std::this_thread::sleep_for(std::chrono::microseconds(sleepTime - timeDelta));
        }
    }


    if (afterDesktopFlags != 0 && !(flags & ISF_SKIP_AFTER_FLAGS)) {
        if (flags & ISF_EXACTLY_BEFORE_FLAGS ? !ExactlySetDesktopFlags(folderView, afterDesktopFlags)
                                             : !SetDesktopFlags(folderView, afterDesktopFlags)) {
            PY_SET_ERROR_STR("Error while setting after_desktop_flags."
                             " Maybe `after_desktop_flags` is incorrect?",
                             PyExc_ValueError);
            return NULL;
        }
    }

    if (!(flags & ISF_SKIP_DEFAULT_AFTER_FLAGS)) {
        folderView->SetCurrentFolderFlags(FWF_SNAPTOGRID, currentFolderFlags);
    }

    temp_obj = PyObject_CallMethod(transition_handler, "handle_final", NULL);
    Py_XDECREF(temp_obj);
    if (temp_obj == NULL) {
        PY_SET_ERROR_STR("Error occurred whil executing `handle_final` ", PyExc_RuntimeError);
        errorOccurred = true;
    }

    Py_DECREF(transition_handler);
    delete[] iconsStorage;
    delete[] calculatedIconsPosition;
    delete[] targetIconsID;

    if (errorOccurred) {
        /* The Error must be set in the same place as the errorOccurred */
        return NULL;
    }

    return missed_icons;
}

/*
 * Get full desktop icons list
 */
PyDoc_STRVAR(positioner_c_part_get_icons_data_doc,
"get_icons_data() -> Sequence[Dict[str, Any]]"
"\n\n"
"Gathers information about the current desktop icons,"
" and returns it as a list of dictionaries");

static PyObject*
positioner_c_part_get_icons_data(PyObject *self, char *Py_UNUSED(ignored))
{
    PyObject* icons_data = PyDict_New();
    CComPtr<IShellFolder> spFolder;
    CComPtr<IEnumIDList> spEnum;

    IFolderView2* folderView;
    PCPFolderViewObject* folder_view = (PCPFolderViewObject*)
                                       (PyObject_GetAttrString(self, "_folder_view"));
    folderView = folder_view->getView();
    Py_DECREF(folder_view);

    if (!folderView) {
        PY_SET_OSERROR_STR("Unknown Error");
        return NULL;
    }

    folderView->GetFolder(IID_PPV_ARGS(&spFolder));

    if (folderView->Items(SVGIO_ALLVIEW, IID_PPV_ARGS(&spEnum)) != S_OK) {
        PY_SET_FOLDER_VIEW_ERROR;
        return NULL;
    }

    int count = 0;
    for (CComHeapPtr<ITEMID_CHILD> spidl;
        spEnum->Next(1, &spidl, nullptr) == S_OK;
        spidl.Free(), count++) {

        POINT pt;
        STRRET str;
        UINT spidl_cb = ILGetSize(spidl);
        CHAR* idRepr = new CHAR[static_cast<long long>(spidl_cb) * 2 + 1];
        WCHAR itemPath[MAX_PATH];
        CComHeapPtr<WCHAR> spszName;

        spFolder->GetDisplayNameOf(spidl, SHGDN_NORMAL, &str);
        StrRetToStr(&str, spidl, &spszName);
        folderView->GetItemPosition(spidl, &pt);
        SHGetPathFromIDListW(spidl, itemPath);
        PIDLAsHex(spidl, spidl_cb, idRepr);

        PyObject* current_icon_data = Py_BuildValue("{s:u,s:u,s:O,s:l,s:l}",
                                                    "display_name", spszName,
                                                    "path", itemPath,
                                                    "is_virtual", itemPath[0] == '\0' ? Py_True : Py_False,
                                                    "x", pt.x,
                                                    "y", pt.y);

        PyDict_SetItemString(icons_data, PyUnicode_FromWideChar(itemPath), current_icon_data);

        Py_XDECREF(current_icon_data);

        delete[] idRepr;
    }

    return icons_data;
}


static PyObject*
test_func(PyObject* self, char* Py_UNUSED(ignored))
{
    PrintPyObj(PyLong_FromUnsignedLong(buildTrueMask(0)));

    Py_RETURN_NONE;
}

/*
 * List of functions to add to positioner_c_part in exec_positioner_c_part().
 */
static PyMethodDef positioner_c_part_functions[] = {
    { "test", (PyCFunction)test_func, METH_NOARGS, NULL },
    { "set_icons_data", (PyCFunction)positioner_c_part_set_icons_data, METH_VARARGS | METH_KEYWORDS, positioner_c_part_set_icons_data_doc },
    { "get_icons_data", (PyCFunction)positioner_c_part_get_icons_data, METH_NOARGS, positioner_c_part_get_icons_data_doc },

    { "get_desktop_flags", (PyCFunction)positioner_c_part_get_desktop_flags, METH_NOARGS, positioner_c_part_get_desktop_flags_doc },
    { "switch_desktop_flags", (PyCFunction)positioner_c_part_switch_desktop_flags, METH_O, positioner_c_part_switch_desktop_flags_doc },
    { "exactly_set_desktop_flags", (PyCFunction)positioner_c_part_exactly_set_desktop_flags, METH_O, positioner_c_part_exactly_set_desktop_flags_doc },
    { "set_desktop_flags", (PyCFunction)positioner_c_part_set_desktop_flags, METH_O, positioner_c_part_set_desktop_flags_doc },
    { "unset_desktop_flags", (PyCFunction)positioner_c_part_unset_desktop_flags, METH_O, positioner_c_part_unset_desktop_flags_doc },
    { NULL, NULL, 0, NULL } /* marks end of array */
};

/*
 * Initialize positioner_c_part. May be called multiple times, so avoid
 * using static state.
 */
int exec_positioner_c_part(PyObject *module)
{
    /* Init COM interface */
    if (!SUCCEEDED(CoInitialize(NULL))) {
        PY_SET_ERROR_STR("CoInitialize failure", PyExc_OSError);
        return -1;
    }

    if (PyType_Ready(&TransitionHandlerType) < 0) {
        PY_SET_ERROR_STR("TransitionHandlerType finalization error", PyExc_TypeError);
        return -1;
    }

    Py_INCREF(&TransitionHandlerType);
    if (PyModule_AddObject(module, "TransitionHandler", (PyObject*)&TransitionHandlerType) < 0) {
        Py_DECREF(&TransitionHandlerType);
        PY_SET_ERROR_STR("TransitionHandlerType registration error", PyExc_TypeError);
        return -1;
    }

    if (PyType_Ready(&PCPFolderViewType) < 0) {
        PY_SET_ERROR_STR("PCPFolderViewType finalization error", PyExc_TypeError);
        return -1;
    }

    PyModule_AddObject(module, "_folder_view",
                       PyObject_CallObject((PyObject*)&PCPFolderViewType, NULL));
    PyModule_AddFunctions(module, positioner_c_part_functions);

    PyModule_AddStringConstant(module, "__author__", "S0D3S");
    //PyModule_AddStringConstant(module, "__version__", "1.0.0"); // unused
    PyModule_AddIntConstant(module, "year", 2023);

    PyModule_AddIntConstant(module, "HANDLER_RC_FINAL_POS", HANDLER_RC_FINAL_POS);
    PyModule_AddIntConstant(module, "HANDLER_RC_MORE_ITER", HANDLER_RC_MORE_ITER);
    PyModule_AddIntConstant(module, "HANDLER_RC_ALREADY_FINAL", HANDLER_RC_ALREADY_FINAL);
    PyModule_AddIntConstant(module, "HANDLER_RC_FATED", HANDLER_RC_FATED);

    PyModule_AddIntConstant(module, "HANDLER_CC_NORMAL", HANDLER_CC_NORMAL);
    PyModule_AddIntConstant(module, "HANDLER_CC_LAST_CALL", HANDLER_CC_LAST_CALL);

    PyModule_AddIntConstant(module, "ISF_SKIP_DEFAULT_BEFORE_FLAGS", ISF_SKIP_DEFAULT_BEFORE_FLAGS);
    PyModule_AddIntConstant(module, "ISF_SKIP_DEFAULT_AFTER_FLAGS", ISF_SKIP_DEFAULT_AFTER_FLAGS);
    PyModule_AddIntConstant(module, "ISF_SKIP_DEFAULT_FLAGS", ISF_SKIP_DEFAULT_FLAGS);
    PyModule_AddIntConstant(module, "ISF_SKIP_BEFORE_FLAGS", ISF_SKIP_BEFORE_FLAGS);
    PyModule_AddIntConstant(module, "ISF_SKIP_AFTER_FLAGS", ISF_SKIP_AFTER_FLAGS);
    PyModule_AddIntConstant(module, "ISF_SKIP_FLAGS", ISF_SKIP_FLAGS);
    PyModule_AddIntConstant(module, "ISF_EXACTLY_BEFORE_FLAGS", ISF_EXACTLY_BEFORE_FLAGS);
    PyModule_AddIntConstant(module, "ISF_EXACTLY_AFTER_FLAGS", ISF_EXACTLY_AFTER_FLAGS);
    PyModule_AddIntConstant(module, "ISF_EXACTLY_FLAGS", ISF_EXACTLY_FLAGS);
    PyModule_AddIntConstant(module, "ISF_FORBID_NONE_TRANSITION", ISF_FORBID_NONE_TRANSITION);

    return 0;
}

/*
 * Documentation for positioner_c_part.
 */
PyDoc_STRVAR(positioner_c_part_doc,
"The positioner part is forced to be written in C."
"It interacts with the WinAPI part related to the Desktop and Views.");


static PyModuleDef_Slot positioner_c_part_slots[] = {
    { Py_mod_exec, exec_positioner_c_part },
    { 0, NULL }
};

static PyModuleDef positioner_c_part_def = {
    PyModuleDef_HEAD_INIT,
    "positioner_c_part",
    positioner_c_part_doc,
    0,              /* m_size */
    NULL,           /* m_methods */
    positioner_c_part_slots,
    NULL,           /* m_traverse */
    NULL,           /* m_clear */
    NULL,           /* m_free */
};

PyMODINIT_FUNC PyInit_positioner_c_part()
{
    return PyModuleDef_Init(&positioner_c_part_def);
}

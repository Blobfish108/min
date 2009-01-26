#ifndef _MIN_H_
#define _MIN_H_

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <limits.h>
#include "kvec.h"
#include "khash.h"

#define MIN_ALLOC(T)          (T *)malloc(sizeof(T))
#define MIN_ALLOC_N(T,N)      (T *)malloc(sizeof(T)*(N))

#define MIN_MEMZERO(X,T)      memset((X), 0, sizeof(T))
#define MIN_MEMZERO_N(X,T,N)  memset((X), 0, sizeof(T)*(N))
#define MIN_MEMCPY(X,Y,T)     memcpy((X), (Y), sizeof(T))
#define MIN_MEMCPY_N(X,Y,T,N) memcpy((X), (Y), sizeof(T)*(N))

#define MIN_STR(x)            MinString2(lobby, (x))
#define MIN_STR_PTR(x)        ((struct MinString *)(x))->ptr
#define MIN_STR_LEN(x)        ((struct MinString *)(x))->len
#define MIN_ARRAY_PUSH(x,i)   kv_push(OBJ, (MIN_ARRAY(x))->kv, (i))
#define MIN_ARRAY_AT(x,i)     kv_A((MIN_ARRAY(x))->kv, (i))
#define MIN_ARRAY_SIZE(x)     kv_size(((struct MinArray *)(x))->kv)
#define MIN_CTYPE(x,T)        (assert(MIN_IS_TYPE(x,T)),(struct Min##T *)(x))
#define MIN_STRING(x)         MIN_CTYPE(x,String)
#define MIN_ARRAY(x)          MIN_CTYPE(x,Array)
#define MIN_VTABLE(x)         MIN_CTYPE(x,VTable)
#define MIN_CLOSURE(x)        MIN_CTYPE(x,Closure)
#define MIN_MESSAGE(x)        MIN_CTYPE(x,Message)
#define MIN_FIXNUM(x)         MIN_CTYPE(x,Fixnum)
#define MIN_OBJ(x)            ((struct MinObject *)(x))
#define MIN_VT(x)             (MIN_OBJ(x)->vtable)
#define MIN_VT_FOR(T)         (lobby->vtables[MIN_T_##T])
#define MIN_TYPE(x)           (MIN_IS_FIX(x) ? MIN_T_Fixnum : MIN_OBJ(x)->type)
#define MIN_IS_TYPE(x,T)      (MIN_TYPE(x) == MIN_T_##T)

#define MIN_NIL               ((OBJ)0)
#define MIN_SHIFT             8
#define MIN_NUM_FLAG          0x01

#define INT2FIX(i)            (OBJ)((i) << MIN_SHIFT | MIN_NUM_FLAG)
#define FIX2INT(i)            (int)((i) >> MIN_SHIFT)
#define MIN_IS_FIX(x)         (((x) & MIN_NUM_FLAG) == MIN_NUM_FLAG)
#define MIN_BOX(x)            (MIN_IS_FIX(x) ? MinFixnum(lobby, FIX2INT(x)) : (x))

#define MIN                   struct MinLobby *lobby, OBJ closure, OBJ self
#define LOBBY                 struct MinLobby *lobby
#define MIN_OBJ_HEADER        OBJ vtable; int type

#define min_send(RCV, MSG, ARGS...) ({  \
  OBJ r = MIN_BOX((OBJ)(RCV));  \
  struct MinClosure *c = MIN_CLOSURE(min_bind(lobby, r, (MSG)));  \
  c->method(lobby, (OBJ)c, r, ##ARGS);  \
})
#define min_send2(RCV, MSG, ARGS...) min_send((RCV), MIN_STR(MSG), ##ARGS)

#define min_add_method(VT, MSG, FUNC) \
  MinVTable_add_method(lobby, 0, (VT), MIN_STR(MSG), (MinMethod)(FUNC));

#define MIN_REGISTER_TYPE(T, vt) ({ \
  OBJ obj = MinVTable_allocate(lobby, 0, vt); \
  MinObject_set_slot(lobby, 0, lobby->lobby, MIN_STR(#T), obj); \
  MinObject_set_slot(lobby, 0, obj, lobby->String_type, MIN_STR(#T)); \
  vt; \
})

#define MIN_CREATE_TYPE(T) \
  MIN_REGISTER_TYPE(T, MIN_VT_FOR(T) = MinVTable_delegated(lobby, 0, MIN_VT_FOR(Object)))

#define MIN_EVAL_ARG(ARG) \
  MIN_IS_TYPE((ARG), Message) \
    ? MinMessage_eval_on(lobby, 0, (ARG), self, self) \
    : (ARG)

typedef unsigned long OBJ;

KHASH_MAP_INIT_INT(OBJ, OBJ)

enum MIN_T {
  MIN_T_Object, MIN_T_VTable, MIN_T_Message, MIN_T_Closure, MIN_T_String, MIN_T_Fixnum, MIN_T_Float, MIN_T_Array,
  MIN_T_MAX /* keep last */
};

struct MinLobby {
  OBJ lobby;
  OBJ vtables[MIN_T_MAX];
  OBJ strings;
  OBJ String_lookup;
  OBJ String_newline;
  OBJ String_dot;
  OBJ String_type;
  OBJ String_sq_bra;
  OBJ String_eq;
};

typedef OBJ (*MinMethod)(MIN, ...);

struct MinVTable {
  MIN_OBJ_HEADER;
  OBJ parent;
  kh_OBJ_t *kh;
};

struct MinObject {
  MIN_OBJ_HEADER;
};

struct MinClosure {
  MIN_OBJ_HEADER;
  MinMethod method;
  OBJ data;
};

struct MinString {
  MIN_OBJ_HEADER;
  size_t len;
  char  *ptr;
};

struct MinFixnum {
  MIN_OBJ_HEADER;
  int value;
};

struct MinMessage {
  MIN_OBJ_HEADER;
  OBJ name;
  OBJ arguments;
  OBJ next;
  OBJ previous;
  OBJ value;
};

struct MinArray {
  MIN_OBJ_HEADER;
  kvec_t(OBJ) kv;
};

struct MinParseState {
  struct MinLobby *lobby;
  OBJ message;
  int curline;
};

/* lobby */
struct MinLobby *MinLobby();
void MinLobby_destroy(LOBBY);

/* message */
OBJ MinMessage(LOBBY, OBJ name, OBJ arguments, OBJ value);
OBJ MinMessage_eval_on(MIN, OBJ context, OBJ receiver);
void MinMessage_init(LOBBY);

/* vtable */
OBJ MinVTable_delegated(MIN);
OBJ MinVTable_allocate(MIN);
OBJ MinVTable_lookup(MIN, OBJ name);
OBJ MinVTable_add_closure(MIN, OBJ name, OBJ clos);
OBJ MinVTable_add_method(MIN, OBJ name, MinMethod method);
OBJ MinVTable_dump(MIN);
void MinVTable_init(LOBBY);

/* object */
OBJ min_bind(LOBBY, OBJ receiver, OBJ msg);
OBJ MinObject_set_slot(MIN, OBJ name, OBJ value);
OBJ MinObject_dump(MIN);
void MinObject_init(LOBBY);

/* string */
OBJ MinString(LOBBY, char *str, size_t len);
OBJ MinString2(LOBBY, const char *str);
OBJ MinString_concat(MIN, OBJ other);
void MinStringTable_init(LOBBY);
void MinString_init(LOBBY);
OBJ min_sprintf(LOBBY, const char *fmt, ...);

/* number */
OBJ MinFixnum(LOBBY, int v);
void MinFixnum_init(LOBBY);

/* array */
OBJ MinArray(LOBBY);
OBJ MinArray2(LOBBY, int argc, ...);
void MinArray_init(LOBBY);

/* lemon */
OBJ min_parse(LOBBY, char *string, char *filename);
void *MinParserAlloc(void *(*)(size_t));
void MinParser(void *, int, OBJ, struct MinParseState *);
void MinParserFree(void *, void (*)(void*));
void MinParserTrace(FILE *stream, char *zPrefix);

#endif /* _MIN_H_ */

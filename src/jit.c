#include "mruby.h"

#ifndef MRB_NAN_BOXING
#error must enable MRB_NAN_BOXING for mruby-jit.
#endif
#ifndef MRB_USE_IV_SEGLIST
#error must enable MRB_USE_IV_SEGLIST for mruby-jit.
#endif

void
mrb_mruby_jit_gem_init(mrb_state* mrb)
{
}

void
mrb_mruby_jit_gem_final(mrb_state* mrb)
{
}

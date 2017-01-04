
// Include the Ruby headers and goodies
#include "ruby.h"
#include "pathname.c"

// Defining a space for information and references about the module to be stored internally
VALUE Delfos = Qnil;
extern VALUE Delfos;

VALUE FileSystem = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_delfos();


static VALUE
path_expand_path(int argc, VALUE *argv, VALUE self);

// The initialization method for this module
void Init_shim() {
	Delfos = rb_define_module("Delfos");
  FileSystem = rb_define_module_under(Delfos, "FileSystem");

  rb_define_method(FileSystem, "expand_path", path_expand_path, -1);
}

MRuby::Gem::Specification.new('mruby-jit') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mruby-jit developers'
end

patch_dir = "#{File.dirname(__FILE__)}/patch"

MRuby.each_target do |target|
  cc.flags << (ENV['CFLAGS'] || %w(-g -O3 -Wall -Werror-implicit-function-declaration -freg-struct-return -fomit-frame-pointer -m32))
  linker.flags << (ENV['LDFLAGS'] || %w(-lm -m32))
  linker.libraries << "stdc++"
  cxx.flags = cc.flags + %w(-fno-operator-names)
  cxx.include_paths << "#{File.dirname(__FILE__)}/xbyak"

  patch "include/mruby.h", "#{patch_dir}/mruby.h.patch"
  patch "include/mrbconf.h", "#{patch_dir}/mrbconf.h.patch"
  patch "include/mruby/irep.h", "#{patch_dir}/irep.h.patch"
  patch "include/mruby/value.h", "#{patch_dir}/value.h.patch"
  patch "include/mruby/variable.h", "#{patch_dir}/variable.h.patch"
  patch "src/class.c", "#{patch_dir}/class.c.patch"
  patch "src/codegen.c", "#{patch_dir}/codegen.c.patch"
  patch "src/dump.c", "#{patch_dir}/dump.c.patch"
  patch "src/gc.c", "#{patch_dir}/gc.c.patch"
  patch "src/init.c", "#{patch_dir}/init.c.patch"
  patch "src/load.c", "#{patch_dir}/load.c.patch"
  patch "src/proc.c", "#{patch_dir}/proc.c.patch"
  patch "src/state.c", "#{patch_dir}/state.c.patch"
  patch "src/variable.c", "#{patch_dir}/variable.c.patch"
  patch "src/vm.c", "#{patch_dir}/vm.c.patch"
end

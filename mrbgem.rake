MRuby::Gem::Specification.new('mruby-jit') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mruby-jit developers'
end

dir = File.dirname(__FILE__)
load "#{dir}/tasks/mruby_patch.rake"

MRuby.each_target do |target|
  patch_dir = "#{dir}/patch"
  cc.flags << (ENV['CFLAGS'] || %w(-g -O3 -Wall -Werror-implicit-function-declaration -freg-struct-return -fomit-frame-pointer -m32))
  linker.flags << (ENV['LDFLAGS'] || %w(-lm -m32))
  linker.libraries << "stdc++"
  cxx.flags = cc.flags + %w(-fno-operator-names)
  cxx.include_paths << "#{dir}/xbyak"
  cc.include_paths.unshift "#{build_dir}/include", "#{dir}/include"
  cxx.include_paths.unshift "#{build_dir}/include", "#{dir}/include"

  patchs = []
  patchs << patch("include/mruby.h", "#{patch_dir}/mruby.h.patch")
  patchs << patch("include/mrbconf.h", "#{patch_dir}/mrbconf.h.patch")
  patchs << patch("include/mruby/irep.h", "#{patch_dir}/irep.h.patch")
  patchs << patch("include/mruby/value.h", "#{patch_dir}/value.h.patch")
  patchs << patch("include/mruby/variable.h", "#{patch_dir}/variable.h.patch")
  patchs << patch("src/class.c", "#{patch_dir}/class.c.patch")
  patchs << patch("src/codegen.c", "#{patch_dir}/codegen.c.patch")
  patchs << patch("src/dump.c", "#{patch_dir}/dump.c.patch")
  patchs << patch("src/gc.c", "#{patch_dir}/gc.c.patch")
  patchs << patch("src/init.c", "#{patch_dir}/init.c.patch")
  patchs << patch("src/load.c", "#{patch_dir}/load.c.patch")
  patchs << patch("src/proc.c", "#{patch_dir}/proc.c.patch")
  patchs << patch("src/state.c", "#{patch_dir}/state.c.patch")
  patchs << patch("src/variable.c", "#{patch_dir}/variable.c.patch")
  patchs << patch("src/vm.c", "#{patch_dir}/vm.c.patch")
  task :patch => patchs

  coreobjs = Dir.glob("#{dir}/core/src/*.{c,cc,cpp}").map do |f|
    o = objfile(f.relative_path_from(dir).to_s.pathmap("#{build_dir}/%X"))
    compiler = {:c => cc, :cc => cxx, :cpp => cxx}[f[/[^.]*$/].intern]
    file o => f do |t|
      compiler.run t.name, t.prerequisites.first, [], ["#{build_dir}/src", "#{MRUBY_ROOT}/src"]
    end
    o
  end
  self.libmruby << coreobjs
  file libfile("#{build_dir}/lib/libmruby_core") => coreobjs
end

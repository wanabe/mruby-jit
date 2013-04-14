MRuby::Gem::Specification.new('mruby-jit') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mruby-jit developers'
end

patch_dir = "#{File.dirname(__FILE__)}/patch"

module MRuby
  class PatchTarget
    @@table = {}
    def self.[](src, dst)
      if !@@table[dst]
        FileUtils.mkdir_p File.dirname(dst)
        FileUtils.cp src, dst
        @@table[dst] = new(dst)
      end
      @@table[dst]
    end

    attr_reader :match
    def initialize(fname)
      @fname = fname
      @content = open(fname, "r") {|f| f.readlines}
      @content.each {|l| l.chomp!}
    end
    def apply(patch)
      @line = 0
      begin
        case patch
        when String
          instance_eval(open(patch, "r") {|f| f.read}, patch)
        when Proc
          instance_eval(&patch)
        end
      rescue Exception
        open(@fname + ".err", "w") {|f| f.puts @content}
        raise
      end
      open(@fname, "w") {|f| f.puts @content}
    end

    def seek(*patterns)
      line = @line
      patterns.each do |pattern|
        case pattern
        when Integer
          line += pattern
          raise "out of range" unless @content[line]
        when :mark
          mark(line)
        else
          until pattern === @content[line]
            line += 1
            raise "can't find #{pattern}" unless @content[line]
          end
        end
      end
      @line = line
      @match = $~
      self
    end

    def insert(patch)
      patch = yield(patch, @match) if block_given?
      patch = patch.scan(/.*\n|.+$/)
      patch.each {|l| l.chomp!}
      @content[@line, 0] = patch
      @line += patch.length
      self
    end

    def mark(line = @line)
      @mark = line
      self
    end

    def count
      @line - @mark + 1
    end

    def rest
      @mark = line = @line
      @line = @content.length - 1
      if block_given?
        yield
        @line = line
      end
    end

    def each(pattern = nil, &b)
      line = @line
      @content[@mark, count].each_with_index do |l, i|
        if !pattern || pattern === l
          @line = @mark + i
          @match = $~
          yield l
        end
      end
      @line = line
    end

    def delete
      @content[@mark, count] = []
      @line = @mark
      self
    end

    def change(patch)
      delete
      insert patch
    end
  end # PatchTarget

  class Build
    def libmruby_core
      @libmruby_core ||= []
    end
    def patchs
      @patchs ||= []
    end
    # usage:
    #
    #   patch "path/from/mruby/root", "path/to/patch"
    #     or
    #   patch "path/from/mruby/root", __FILE__ do ... end
    #
    def patch(file, patch = nil, &b)
      src = "#{root}/#{file}"
      dst = "#{build_dir}/#{file}"
      obj = objfile(dst.sub(/\.cc?$/, ""))
      dir = File.dirname(src)
      src = [src, patch] if patch
      patch = b if b
      task :patch => dst
      patchs << dst
      file dst => src do |t|
        PatchTarget[t.prerequisites.first, t.name].apply(patch)
      end
      return unless obj
      file obj => dst do |t|
        cc.run t.name, t.prerequisites.first, [], [dir]
      end
    end
  end
end # MRuby

MRuby.each_target do |target|
  cc.flags << (ENV['CFLAGS'] || %w(-g -O3 -Wall -Werror-implicit-function-declaration -freg-struct-return -fomit-frame-pointer -m32))
  linker.flags << (ENV['LDFLAGS'] || %w(-lm -m32))
  linker.libraries << "stdc++"
  cxx.flags = cc.flags + %w(-fno-operator-names)
  cxx.include_paths << "#{File.dirname(__FILE__)}/xbyak"
  cc.include_paths.unshift "#{build_dir}/include"
  cxx.include_paths.unshift "#{build_dir}/include"

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
  self.libmruby << patchs
end

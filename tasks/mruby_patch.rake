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
      file dst => src do |t|
        PatchTarget[t.prerequisites.first, t.name].apply(patch)
      end
      if obj
        file obj => dst do |t|
          cc.run t.name, t.prerequisites.first, [], [dir]
        end
      end
      dst
    end
  end
end # MRuby

task :default => :patch
task :patch => []

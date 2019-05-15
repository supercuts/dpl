require 'tempfile'
require 'zip'

module Dpl
  class Zip < Struct.new(:src, :dest, :opts)
    def zip
      if zip?
        copy
      elsif dir?
        zip_dir
      else
        zip_file
      end
    end

    def zip_dir
      create(Dir.glob(*glob).reject { |path| dir?(path) })
    end

    def zip_file
      create(File.dirname(src), target, [src])
    end

    def create(files)
      ::Zip::File.open(dest, ::Zip::File::CREATE) do |zip|
        files.each do |file|
          zip.add(file.sub("#{src}/", ''), file)
        end
      end
      File.new(dest)
    end

    def zip?
      exts.include?(File.extname(src))
    end

    def dir?(path = src)
      File.directory?(path)
    end

    def cp
      FileUtils.cp(src, dest)
    end

    def glob
      glob = ["#{src}/**/*"]
      glob << File::FNM_DOTMATCH if dot_match?
      glob
    end

    def dot_match?
      opts[:dot_match]
    end

    def exts
      opts[:exts] ||= %w(.zip .jar)
    end

    def opts
      super || {}
    end
  end
end
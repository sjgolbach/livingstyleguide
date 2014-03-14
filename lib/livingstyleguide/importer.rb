if defined?(Sprockets)
  class LivingStyleGuide::Importer < Sprockets::SassImporter
    def initialize(scope, root)
      super(scope, root)
    end
  end
else
  puts ":("
  class LivingStyleGuide::Importer < Sass::Importers::Filesystem
    def initialize(scope, root)
      super(root)
    end
  end
end

LivingStyleGuide::Importer.class_eval do

  def find_relative(name, base, options, absolute = false)
    @options = options
    find_markdown(File.dirname(options[:filename]) + '/' + name)
    super(name, base, options)
  end

  def find(name, options)
    @options = options
    if defined?(Rails) and defined?(Sprockets) and name =~ Sprockets::SassImporter::GLOB
      glob_imports(name, Pathname.new(File.dirname(options[:filename]) + "/*"), options)
    else
      super(name, options)
    end
  end

  ### ONLY TEMPORARY:

  def each_globbed_file(glob, base_pathname, options)
    Dir["#{base_pathname}/#{glob}"].sort.each do |filename|
      next if filename == options[:filename]
      yield filename if File.directory?(filename) || filename =~ /\.s[ac]ss$/
    end
  end

  def glob_imports(glob, base_pathname, options)
    contents = ""
    each_globbed_file(glob, base_pathname.dirname, options) do |filename|
      if File.directory?(filename)
        depend_on(filename)
      elsif filename =~ /\.s[ac]ss$/
        contents << "@import #{Pathname.new(filename).relative_path_from(base_pathname.dirname).to_s.inspect};\n"
      end
    end
    return nil if contents.empty?
    Sass::Engine.new(contents, options.merge(
      :filename => base_pathname.to_s,
      :importer => self,
      :syntax => :scss
    ))
  end

  ###

  private
  def find_markdown(sass_filename)
    files << sass_filename
    glob = "#{sass_filename.sub(/\.s[ac]ss$/, '')}.md"
    Dir.glob(glob) do |markdown_filename|
      files << markdown_filename
      markdown << File.read(markdown_filename)
    end
  end

  private
  def files
    @options[:living_style_guide].files
  end

  private
  def markdown
    @options[:living_style_guide].markdown
  end

end


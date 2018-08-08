module Tofuwiki
  class Expander
    # Takes any wiki link that stands alone on a line and expands it
    # this is different from Tofuwiki::WIKI_WORD in that it requires ^\s* before the
    # first letter

    WIKI_LINK_PATTERN =  /^\s*([a-z0-9]\w+\.)?[A-Z][a-z]+[A-Z0-9]\w*\s*$/

    attr_reader :mode, :file, :processed_files
    attr_reader :repo_path, :file_path
    attr_reader :expanded_text

    include PathHelper

    def initialize(repo_path, mode, file)
      @repo_path = ensure_path(repo_path)
      @mode = mode
      @file_path = ensure_path(file)
      @file = repo_relative(file).to_s
      @processed_files = []
    end

    def seamless?
      mode == 'seamless'
    end

    def seamful?
      mode == 'seamful'
    end

    def indent(text, level)
      return text if seamless?
      return text if level == 0
      ('|' * level) + ' ' +  text
    end

    def divider
      '+' + '-' * 78 + '+'
    end

    def register_in_expansion(text, inline=false)
      @expanded_text ||= ''
      full_text = inline ? text : text + "\n"
      @expanded_text << full_text
    end

    def recursive_expand(file_path, name, level=0)
      processed_files << file_path
      lines = file_path.readlines
      title = lines.shift # takes title
      lines = lines.join.strip.split("\n")
      if seamful?
        register_in_expansion divider unless level == 0
        register_in_expansion indent(title, level)
      end
      lines.each do |line|
        # note that the wiki link must be alone on the line to be expanded
        if line =~ WIKI_LINK_PATTERN
          link = line.strip
          if link =~ /(\A|\s)[A-Z]/ # short link in namespace (relative link)
            link = [name.namespace, link].join('.')
          end
          link_file_path = in_repo(link.to_file_path)
          if link_file_path.file? && !processed_files.include?(link_file_path)
            recursive_expand(link_file_path, link, level + 1) # recursive call
          elsif processed_files.include?(link_file_path)
            register_in_expansion indent("#{link} [[already expanded]]", level)
          elsif !link_file_path.file?
            register_in_expansion indent("#{link} [[no file found]]", level)
          else
            register_in_expansion indent("#{link}", level)
          end
        else
          register_in_expansion indent(line, level)
        end
      end
      register_in_expansion divider if seamful? && level != 0
    end

    def expand
      recursive_expand(file_path, file.to_page_title)
      expanded_text
    end

  end
end

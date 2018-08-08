require 'string_ext'
require 'path_helper'
module Template_Substitution; end
module Tofuwiki
  VERSION = '0.9.8.3'
  WIKI_WORD = /\b([a-z0-9][\w_]+\.)?[A-Z][a-z]+[A-Z0-9]\w*\b/
  SCHEMES = %w{https http file soyfile}
  HYPERLINK = %r|\b(?:#{SCHEMES.join('|')})://[^ >)\n\]]+|

  def self.run
    require 'getoptlong'

    opts = GetoptLong.new(
      [ '--help',    '-h',     GetoptLong::NO_ARGUMENT],
      [ '--version', '-v',     GetoptLong::NO_ARGUMENT],
      [ '--html',              GetoptLong::NO_ARGUMENT],
      [ '--markdown',          GetoptLong::NO_ARGUMENT],
      [ '--absolute',          GetoptLong::NO_ARGUMENT],
      [ '--relative',          GetoptLong::NO_ARGUMENT],
      [ '--install-plugin',    GetoptLong::NO_ARGUMENT],
      [ '--page',              GetoptLong::REQUIRED_ARGUMENT],
      [ '--index',             GetoptLong::REQUIRED_ARGUMENT],
    )

    usage =->(version_only=false)  do
      puts "tofuwiki #{Tofuwiki::VERSION}"
      puts "by Daniel Choi dhchoi@gmail.com"
      exit if version_only
      puts
      puts <<-END
---
Usage: tofuwiki

Run the command in a directory you've made to contain tofuwiki files.

tofuwiki will open the most recently modified wiki file or create a file
called main/HomePage. 

Parse to html:
  --html
    assume that wiki-files are in markdown syntax:
      --markdown
    replace default haml-page-template with the one supplied:
      --page template-file
    replace default haml-index-template with the one supplied:
      --index template-file
      --absolute
      generate absolute file://-style links
      --relative
      generate relative ../-style links
Install the tofuwiki vim plugin:
  --install-plugin
Show this help:
  [--help, -h]
Show version info:
  [--version, -v]
---
      END
      exit
    end
    install_plugin = false
    html           = false
    md             = false
    index = page = nil
    relative_soyfile = false
    opts.each do |opt, arg|
      case opt
        when '--help' then usage[]
        when '--version' then usage[true]
        when '--html' then html = true
        when '--markdown' then md = true
        when '--install-plugin' then install_plugin = true
        when '--page' then page = arg
        when '--index' then index = arg
        when '--absolute' then relative_soyfile = false
        when '--relative' then relative_soyfile = true
      end
    end
    self.set_substitute %{INDEX_PAGE_TEMPLATE_SUB}.to_sym, index if index
    self.set_substitute %{PAGE_TEMPLATE_SUB}.to_sym, page if page
    self.html_export(md, relative_soyfile) if html
    if install_plugin
      require 'erb'
      plugin_template = File.read(File.join(File.dirname(__FILE__), 'plugin.erb'))
      vimscript_file = File.join(File.dirname(__FILE__), 'tofuwiki.vim')
      plugin_body = ERB.new(plugin_template).result(binding)
      `mkdir -p #{ENV['HOME']}/.vim/plugin`
      File.open("#{ENV['HOME']}/.vim/plugin/tofuwiki_starter.vim", "w") {|f| f.write plugin_body}
    else
      vim = ENV['TOFUWIKI_VIM'] || 'vim'
      vimscript = File.expand_path("../tofuwiki.vim", __FILE__)
      vim_command = "#{vim} -S #{vimscript}"
      exec vim_command
    end unless html
  end

  def self.html_export(markdown, relative_soyfile)
    require 'tofuwiki/html'
    Html.export(markdown, relative_soyfile)
  end

  def self.set_substitute const, substitute_path
    substitute = File.read(substitute_path)
    Template_Substitution.const_set const.to_sym, substitute
  end
end

if __FILE__ == $0
  Tofuwiki.run
end

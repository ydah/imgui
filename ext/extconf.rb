# frozen_string_literal: true

require "rbconfig"
require "shellwords"

ruby = Shellwords.escape(RbConfig.ruby)
extension_dir = File.expand_path(__dir__)
build_dir = File.join(extension_dir, "build")
install_dir = File.join(build_dir, "install")

makefile = <<~MAKEFILE
  RUBY = #{ruby}
  sitearchdir = #{Shellwords.escape(RbConfig::CONFIG.fetch("sitearchdir"))}

  all:
	$(RUBY) #{Shellwords.escape(File.join(extension_dir, "build_cimgui.rb"))} #{Shellwords.escape(build_dir)} #{Shellwords.escape(install_dir)}

  install:
	$(RUBY) #{Shellwords.escape(File.join(extension_dir, "install_cimgui.rb"))} #{Shellwords.escape(install_dir)} "$(DESTDIR)$(sitearchdir)"

  clean:
	@true
MAKEFILE

File.write(File.join(extension_dir, "Makefile"), makefile)

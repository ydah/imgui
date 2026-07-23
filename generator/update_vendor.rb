# frozen_string_literal: true

require "optparse"

require_relative "native_dependency_snapshot"

options = { latest: false, verify: false, checkout: nil }
OptionParser.new do |parser|
  parser.banner = "Usage: ruby generator/update_vendor.rb [--latest | --verify | --checkout SOURCE:DIR]"
  parser.on("--latest", "Refresh snapshots from configured upstream branches") { options[:latest] = true }
  parser.on("--verify", "Verify cached snapshots without network access") { options[:verify] = true }
  parser.on("--checkout SOURCE:DIR", "Checkout a complete pinned upstream source tree") do |value|
    options[:checkout] = value.split(":", 2)
  end
end.parse!

selected_modes = [options[:latest], options[:verify], options[:checkout]].count { |value| value }
abort "--latest, --verify, and --checkout cannot be combined" if selected_modes > 1
abort "--checkout requires SOURCE:DIR" if options[:checkout]&.length == 1

snapshot = ImGuiRuby::NativeDependencySnapshot.new
if options[:checkout]
  snapshot.checkout_source!(*options[:checkout])
elsif options[:verify]
  snapshot.verify!
elsif options[:latest]
  snapshot.refresh!(latest: true)
else
  snapshot.fetch!
end

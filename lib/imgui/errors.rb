# frozen_string_literal: true

module ImGui
  class Error < StandardError; end
  class LibraryLoadError < Error; end
  class MissingSymbolError < Error; end
  class BackendUnavailableError < Error; end
  class NoContextError < Error; end
  class ThreadError < Error; end
  class StackError < Error; end
end

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require "rjb"
require 'active_support/core_ext'
require 'tempfile'
require 'jasper-command-line/version'
require 'jasper-command-line/command_line'
require 'jasper-command-line/jasper'

module JasperCommandLine
  def self.logger=(log)
    @logger = log
  end

  # Get AppleTvConverter logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @logger = logger
  end
end
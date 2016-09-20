#!/usr/bin/env ruby

# Transcode and sync a FLAC library to a portable MP3 library

require_relative "library"

require "fileutils"
require "optparse"

if __FILE__ == $0
    optparse = OptionParser.new do | opts |
        opts.banner = "Usage: #{$0} [FLAC library] [MP3 library]"

        opts.on( "-h", "--help", "Display this help message" ) do
            puts opts
            exit 0
        end
    end

    optparse.parse!

    # Accept two arguments
    raise ArgumentError, "Too few arguments" unless ARGV.length > 1
    raise ArgumentError, "Too many arguments" if ARGV.length > 2

    # Ensure upstream library exists
    FLACDIR = ARGV.at 0
    raise ArgumentError, "FLAC library not found" unless Dir.exist? FLACDIR
    flacLibrary = Library.new FLACDIR

    # Create downstream library if it doesn't exist
    MP3DIR = ARGV.at 1
    FileUtils.mkpath MP3DIR unless Dir.exist? MP3DIR
    raise ArgumentError, "MP3 library not found" unless Dir.exist? MP3DIR

    # Initiate sync
    flacLibrary.sync_to MP3DIR
end

exit 0


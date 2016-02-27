#!/usr/bin/env ruby

# Transcode a FLAC library into MP3
# Keep libraries in sync
# Keep MP3 library file names FAT32-compatible

require_relative "fat32safename"

require "fileutils"

raise ArgumentError, "Too many arguments" unless ARGV.length == 2

FLACDIR = ARGV.at 0
raise ArgumentError, "FLAC library not found" unless Dir.exist? FLACDIR

MP3DIR = ARGV.at 1
FileUtils.mkpath MP3DIR unless Dir.exist? MP3DIR
raise ArgumentError, "MP3 library not found" unless Dir.exist? MP3DIR

# Gather paths to all FLAC media in the flac library
flacPaths = Dir.glob File.join "#{FLACDIR}", "**", "*.flac"

flacPaths.each do | flacPath |
    puts flacPath
end

exit 0


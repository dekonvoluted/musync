#!/usr/bin/env ruby

# Transcode a FLAC library into MP3
# Keep libraries in sync
# Keep MP3 library file names FAT32-compatible

require "fileutils"

raise ArgumentError, "Too many arguments" unless ARGV.length == 2

FLACDIR = ARGV.at 0
raise ArgumentError, "FLAC library not found" unless Dir.exist? FLACDIR

MP3DIR = ARGV.at 1
FileUtils.mkpath MP3DIR unless Dir.exist? MP3DIR
raise ArgumentError, "MP3 library not found" unless Dir.exist? MP3DIR

# Create FAT32-safe file/directory names
def getFAT32SafeName badName
    # Avoid strings longer than 240 characters (with .mp3 extension)
    safeName = badName.slice( 0, 236 )

    # Allow only safe characters
    badCharacters = /[^a-zA-Z0-9\.\-\ ]/
    safeName.gsub! badCharacters, "_"

    # Avoid leading/trailing spaces or dots
    safeName.gsub! /^\s/, "_"
    safeName.gsub! /\s$/, "_"
    safeName.gsub! /^\./, "_"
    safeName.gsub! /\.$/, "_"

    # Avoid empty or "." file names
    safeName = "empty" if safeName.empty?
    safeName = "dot" if safeName == "."

    return safeName
end


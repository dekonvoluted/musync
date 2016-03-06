#!/usr/bin/env ruby

# Transcode a FLAC library into MP3
# Keep libraries in sync
# Keep MP3 library file names FAT32-compatible

require_relative "artfile"
require_relative "fat32"
require_relative "flacfile"

require "fileutils"
require "shellwords"

raise ArgumentError, "Too many arguments" unless ARGV.length == 2

FLACDIR = ARGV.at 0
raise ArgumentError, "FLAC library not found" unless Dir.exist? FLACDIR

MP3DIR = ARGV.at 1
FileUtils.mkpath MP3DIR unless Dir.exist? MP3DIR
raise ArgumentError, "MP3 library not found" unless Dir.exist? MP3DIR

# Gather paths to all FLAC media in the flac library
puts "Reading FLAC libary..."
flacPaths = Dir.glob File.join "#{FLACDIR}", "**", "*.flac"
totalCount = flacPaths.length
puts "Found #{totalCount} songs."

filesToTranscode = Hash.new
flacPaths.each do | flacPath |
    # Get relative path of FLAC file
    flacFile = flacPath.sub /^#{FLACDIR}/, ""

    # Get FAT32 safe relative path for MP3 file
    mp3File = flacFile.sub /flac$/i, "mp3"
    mp3File.split( "/" ).each do | mp3Dir |
        mp3Dir = FAT32.safeName mp3Dir
    end

    # Skip existing mp3 files
    next if File.exist? File.join MP3DIR, mp3File

    # Record files to encode
    filesToTranscode[ flacFile ] = mp3File
end

exit 0 if filesToTranscode.empty?

flacCount = 0
totalCount = filesToTranscode.size
filesToTranscode.each_pair do | flacFile, mp3File |
    flacCount += 1

    # Create missing directories
    unless File.exist? File.join MP3DIR, File.dirname( mp3File )
        puts "#{flacCount}/#{totalCount} Creating #{File.join MP3DIR, File.dirname( mp3File )}"
        FileUtils.mkdir_p File.join MP3DIR, File.dirname( mp3File )
    end

    # Resize artwork if found
    artwork = File.join FLACDIR, File.dirname( flacFile ), "album.jpg"
    if File.exist? artwork
        artFile = File.join MP3DIR, File.dirname( mp3File ), "album.jpg"
    else
        artwork = ""
        artFile = ""
    end

    unless artwork.empty? or File.exist? artFile
        puts "#{flacCount}/#{totalCount} Creating #{File.join File.dirname( mp3File ), File.basename( artFile )}"
        ArtFile.new( artwork ).resize artFile, "300x300"
    end

    puts "#{flacCount}/#{totalCount} Creating #{mp3File}"
    FlacFile.new( File.join FLACDIR, flacFile ).to_mp3 File.join( MP3DIR, mp3File ), artFile
end

exit 0


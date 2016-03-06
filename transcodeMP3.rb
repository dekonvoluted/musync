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
puts "Reading FLAC libary: #{FLACDIR}"
flacPaths = Dir.glob File.join "#{FLACDIR}", "**", "*.flac"
totalCount = flacPaths.length
puts "Found #{totalCount} songs."

puts "Reading MP3 library: #{MP3DIR}"
filesToTranscode = Hash.new
flacPaths.each do | flacPath |
    # Get relative path of FLAC file
    flacFile = flacPath.sub /^#{FLACDIR}\/?/, ""

    # Get FAT32 safe relative path for MP3 file
    mp3File = flacFile.sub /flac$/i, "mp3"
    mp3File = mp3File.split "/"
    mp3File.map! do | mp3Dir |
        FAT32.safeName mp3Dir
    end
    mp3File = File.join mp3File

    # Skip existing mp3 files
    next if File.exist? File.join MP3DIR, mp3File

    # Record files to encode
    filesToTranscode[ flacFile ] = mp3File
end

puts "Found #{filesToTranscode.size} files to transcode."
exit 0 if filesToTranscode.empty?

# Find preferred album artwork
def get_artwork directory
    # Search for suitable artwork by priority
    artPaths = Dir.glob File.join directory, "*.jpg"

    artwork = File.join directory, "album.jpg"
    if artPaths.include? artwork
        return artwork
    end

    artwork = File.join directory, "folder.jpg"
    if artPaths.include? artwork
        return artwork
    end

    artPaths += Dir.glob File.join directory, "*.jpeg"

    artwork = File.join directory, "album.jpeg"
    if artPaths.include? artwork
        return artwork
    end

    artwork = File.join directory, "folder.jpeg"
    if artPaths.include? artwork
        return artwork
    end

    artPaths += Dir.glob File.join directory, "*.png"

    artwork = File.join directory, "album.png"
    if artPaths.include? artwork
        return artwork
    end

    artwork = File.join directory, "folder.png"
    if artPaths.include? artwork
        return artwork
    end

    # Return lone artwork if found
    return artPaths.at 0 if artPaths.size == 1

    # No suitable artwork found
    return ""
end

puts "Writing MP3 library: #{MP3DIR}"
flacCount = 0
totalCount = filesToTranscode.size
filesToTranscode.each_pair do | flacFile, mp3File |
    flacCount += 1

    # Create missing directories
    unless File.exist? File.join MP3DIR, File.dirname( mp3File )
        puts "#{flacCount}/#{totalCount} Creating #{File.dirname( mp3File )}"
        FileUtils.mkdir_p File.join MP3DIR, File.dirname( mp3File )
    end

    # Resize artwork if found
    artwork = get_artwork File.join FLACDIR, File.dirname( flacFile )
    artFile = ""
    unless artwork.empty?
        artFile = File.join MP3DIR, artwork.sub( /^#{FLACDIR}\/?/, "" )

        unless File.exist? artFile
            puts "#{flacCount}/#{totalCount} Creating #{File.join File.dirname( mp3File ), File.basename( artFile )}"
            ArtFile.new( artwork ).resize artFile, "300x300"
        end
    end

    puts "#{flacCount}/#{totalCount} Creating #{mp3File}"
    FlacFile.new( File.join FLACDIR, flacFile ).to_mp3 File.join( MP3DIR, mp3File ), artFile
end

exit 0


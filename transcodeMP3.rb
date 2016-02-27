#!/usr/bin/env ruby

# Transcode a FLAC library into MP3
# Keep libraries in sync
# Keep MP3 library file names FAT32-compatible

require_relative "fat32safename"

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

flacPaths.each_with_index do | flacPath, flacCount |
    # Get relative path from root directory
    flacFile = flacPath.sub /^#{FLACDIR}/, ""

    # Deduce artist, album and song from path
    artist, album, song = flacFile.split "/"
    raise ArgumentError, "Artist/Album/Song hierarchy not found" if artist.empty? or album.empty? or song.empty?

    # Create FAT32-safe artist directory
    f32Artist = getFAT32SafeName artist
    f32ArtistPath = File.join MP3DIR, f32Artist
    unless Dir.exist? f32ArtistPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/"
        Dir.mkdir f32ArtistPath
    end

    # Create FAT32-safe album directory
    f32Album = getFAT32SafeName album
    f32AlbumPath = File.join f32ArtistPath, f32Album
    unless Dir.exist? f32AlbumPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/"
        Dir.mkdir f32AlbumPath
    end

    # Resize artwork if found
    artwork = File.join File.dirname( flacPath ), "album.jpg"
    if File.exist? artwork
        f32ArtworkPath = File.join f32AlbumPath, "album.jpg"
    else
        artwork = ""
        f32ArtworkPath = ""
    end

    artworkResizeCommand = Array.new
    artworkResizeCommand.push "convert"
    artworkResizeCommand.push "-resize 300x300"
    artworkResizeCommand.push Shellwords.escape artwork
    artworkResizeCommand.push Shellwords.escape f32ArtworkPath

    unless artwork.empty? or File.exist? f32ArtworkPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/album.jpg"
        raise "Resizing of artwork failed" unless system( artworkResizeCommand.join( " " ) )
    end
end

exit 0


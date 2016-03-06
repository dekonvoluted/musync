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

flacPaths.each_with_index do | flacPath, flacCount |
    # Get relative path from root directory
    flacFile = flacPath.sub /^#{FLACDIR}/, ""

    # Deduce artist, album and song from path
    artist, album, song = flacFile.split "/"
    raise ArgumentError, "Artist/Album/Song hierarchy not found" if artist.empty? or album.empty? or song.empty?

    # Create FAT32-safe artist directory
    f32Artist = FAT32.safeName artist
    f32ArtistPath = File.join MP3DIR, f32Artist
    unless Dir.exist? f32ArtistPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/"
        Dir.mkdir f32ArtistPath
    end

    # Create FAT32-safe album directory
    f32Album = FAT32.safeName album
    f32AlbumPath = File.join f32ArtistPath, f32Album
    unless Dir.exist? f32AlbumPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/"
        Dir.mkdir f32AlbumPath
    end

    # Prepare to decode FLAC and encode MP3 with ID3V2 tags
    song.sub! /\.flac$/, ".mp3"
    f32Song = FAT32.safeName song
    f32SongPath = File.join f32AlbumPath, f32Song
    next if File.exist? f32SongPath

    # Resize artwork if found
    # Resize artwork if found
    artwork = File.join File.dirname( flacPath ), "album.jpg"
    if File.exist? artwork
        f32ArtworkPath = File.join f32AlbumPath, "album.jpg"
    else
        artwork = ""
        f32ArtworkPath = ""
    end

    unless artwork.empty? or File.exist? f32ArtworkPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/album.jpg"
        ArtFile.new( artwork ).resize f32ArtworkPath, "300x300"
    end

    puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/#{f32Song}"
    FlacFile.new( flacPath ).to_mp3 f32SongPath, f32ArtworkPath
end

exit 0


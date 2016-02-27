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

# Method to retrieve tags from FLAC media
def getFLACTag path, tag
    return %x( metaflac --show-tag="#{tag}" \""#{Shellwords.escape path}"\" ).sub /#{tag}=/, ""
end

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

    # Determine tags
    titleTag = getFLACTag( flacPath, "TITLE" )
    artistTag = getFLACTag( flacPath, "ARTIST" )
    albumTag = getFLACTag( flacPath, "ALBUM" )
    trackNumberTag = getFLACTag( flacPath, "TRACKNUMBER" )
    commentTag = getFLACTag( flacPath, "COMMENT" )
    yearTag = getFLACTag( flacPath, "DATE" )
    genreTag = getFLACTag( flacPath, "GENRE" )

    # Prepare to decode FLAC and encode MP3 with ID3V2 tags
    song.sub! /\.flac$/, ".mp3"
    f32Song = getFAT32SafeName song
    f32SongPath = File.join f32AlbumPath, f32Song

    flacDecodeCommand = Array.new
    flacDecodeCommand.push "flac"
    flacDecodeCommand.push "--decode"
    flacDecodeCommand.push "--silent"
    flacDecodeCommand.push "--stdout"
    flacDecodeCommand.push Shellwords.escape flacPath

    mp3EncodeCommand = Array.new
    mp3EncodeCommand.push "lame"
    mp3EncodeCommand.push "--silent"
    mp3EncodeCommand.push "--preset medium"
    mp3EncodeCommand.push "--id3v2-only"
    mp3EncodeCommand.push "--id3v2-utf16"
    mp3EncodeCommand.push "--tt #{Shellwords.escape titleTag}"
    mp3EncodeCommand.push "--ta #{Shellwords.escape artistTag}"
    mp3EncodeCommand.push "--tl #{Shellwords.escape albumTag}"
    mp3EncodeCommand.push "--tn #{Shellwords.escape trackNumberTag}"
    mp3EncodeCommand.push "--tc #{Shellwords.escape commentTag}"
    mp3EncodeCommand.push "--ty #{Shellwords.escape yearTag}"
    mp3EncodeCommand.push "--tg #{Shellwords.escape genreTag}"
    mp3EncodeCommand.push "--ti #{Shellwords.escape f32ArtworkPath}" unless f32ArtworkPath.empty?
    mp3EncodeCommand.push "-"
    mp3EncodeCommand.push Shellwords.escape f32SongPath

    unless File.exist? f32SongPath
        puts "#{flacCount}/#{totalCount} Creating #{f32Artist}/#{f32Album}/#{f32Song}"
        raise "Encoding media failed" unless system( "#{flacDecodeCommand.join( " " )} | #{mp3EncodeCommand.join( " " )}" )
    end
end

exit 0


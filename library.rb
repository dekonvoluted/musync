require_relative "artfile"
require_relative "flacfile"
require_relative "mp3file"

require "fileutils"

class Library

    # Initialize library at given path
    def initialize libraryPath

        # Check if library path exists
        # Sanitize input path
        @path = File.realpath libraryPath

        # Gather paths to FLAC files
        @mediaFiles = Hash.new

        puts "Reading library..."

        flacPaths = Dir.glob File.join( @path, "**", "*.flac" ), File::FNM_CASEFOLD

        puts "#{flacPaths.size} FLAC files found."

        # Store FLAC files
        flacPaths.each do | flacPath |
            relativePath = flacPath.gsub /^#{@path}\/?/, ""
            relativeDirectory = File.dirname relativePath
            @mediaFiles[ relativeDirectory ] = Array.new if @mediaFiles[ relativeDirectory ].nil?

            flacFile = FlacFile.new relativePath, @path
            @mediaFiles[ relativeDirectory ].push flacFile
        end

        # Gather paths to album artwork
        @artFiles = Hash.new

        artPaths = Dir.glob File.join( @path, "**", "*.jpg" ), File::FNM_CASEFOLD
        artPaths += Dir.glob File.join( @path, "**", "*.jpeg" ), File::FNM_CASEFOLD
        artPaths += Dir.glob File.join( @path, "**", "*.png" ), File::FNM_CASEFOLD

        puts "#{artPaths.size} artwork files found."

        # Store artwork
        artPaths.each do | artPath |
            relativePath = artPath.gsub /^#{@path}\/?/, ""
            relativeDirectory = File.dirname relativePath
            @artFiles[ relativeDirectory ] = Array.new if @artFiles[ relativeDirectory ].nil?

            artFile = ArtFile.new relativePath, @path
            @artFiles[ relativeDirectory ].push artFile
        end
    end

    # Synchronize to downstream library
    def sync_to libraryPath

        # Check if library path exists
        # Sanitize input path
        downstreamBaseDirectory = File.realpath libraryPath

        puts "Syncing to downstream library..."

        # Transcode FLAC media files
        @mediaFiles.each do | relativePath, mediaFileArray |

            # Resize and copy album artwork
            artFileArray = @artFiles[ relativePath ]
            unless artFileArray.nil?
                artFileArray.each do | artFile |

                    # Skip already existing files
                    downstreamArtFilePath = File.join downstreamBaseDirectory, artFile.safe_relative_path
                    next if File.exist? downstreamArtFilePath

                    # Create directory if missing
                    safeRelativeDirectory = File.dirname downstreamArtFilePath
                    FileUtils.mkpath safeRelativeDirectory unless Dir.exist? safeRelativeDirectory

                    puts "Syncing #{artFile.safe_relative_path}"

                    # Resize to destination
                    artFile.resize downstreamArtFilePath, "300x300"
                end
            end

            # Designate destination album artwork
            artFile = artFileArray.at( 0 ) unless artFileArray.nil? or artFileArray.size > 1

            mediaFileArray.each do | flacFile |

                fork do

                    # Skip already existing files
                    downstreamMediaFilePath = File.join downstreamBaseDirectory, flacFile.safe_relative_path.gsub( /flac$/i, "mp3" )
                    next if File.exist? downstreamMediaFilePath

                    # Create directory if missing
                    safeRelativeDirectory = File.dirname downstreamMediaFilePath
                    FileUtils.mkpath safeRelativeDirectory unless Dir.exist? safeRelativeDirectory

                    puts "Syncing #{flacFile.safe_relative_path.gsub /flac$/i, "mp3"}"

                    # Encode mp3 file
                    mp3File = MP3File.new flacFile.safe_relative_path.gsub( /flac$/i, "mp3" ), downstreamBaseDirectory
                    mp3File.set_artPath File.join( downstreamBaseDirectory, artFile.safe_relative_path ) unless artFile.nil?
                    mp3File.set_tags flacFile.tags

                    mp3File.from_wav flacFile.to_wav
                end

                # Wait a second to let log message print
                sleep 1
            end
            Process.waitall
        end
    end
end


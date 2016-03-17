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

        flacPaths = Dir.glob File.join( @path, "**", "*.flac" ), File::FNM_CASEFOLD

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

        # Resize and copy album artwork
        @artFiles.each do | relativePath, artFileArray |
            artFileArray.each do | artFile |

                # Create directory if missing
                safeRelativeDirectory = File.join( downstreamBaseDirectory, File.dirname( artFile.safe_relative_path ) )
                FileUtils.mkpath safeRelativeDirectory unless Dir.exist? safeRelativeDirectory

                # Resize to destination
                artFile.resize File.join( downstreamBaseDirectory, artFile.safe_relative_path ), "300x300"
            end
        end

        # Transcode FLAC media files
        @mediaFiles.each do | relativePath, mediaFileArray |

            # Designate destination album artwork
            artFileArray = @artFiles[ relativePath ]
            artFile = artFileArray.at( 0 ) unless artFileArray.nil? or artFileArray.size > 1

            mediaFileArray.each do | flacFile |

                # Create directory if missing
                safeRelativeDirectory = File.join( downstreamBaseDirectory, File.dirname( flacFile.safe_relative_path ) )
                FileUtils.mkpath safeRelativeDirectory unless Dir.exist? safeRelativeDirectory

                # Encode mp3 file
                mp3File = MP3File.new flacFile.safe_relative_path.gsub( /flac$/i, "mp3" ), downstreamBaseDirectory
                mp3File.set_artPath File.join( downstreamBaseDirectory, artFile.safe_relative_path ) unless artFile.nil?
                mp3File.set_tags flacFile.tags

                mp3File.from_wav flacFile.to_wav
            end
        end
    end
end


require_relative "mufile"

require "shellwords"

class FlacFile < MuFile

    # Specify valid extensions
    @valid_extensions = [ ".flac" ]

    # Specify error message
    @invalid_extension_message = "Invalid extension for FLAC file"

    # Return decoded WAV data
    def to_wav
        # Check if flac exists
        raise "flac: Command not found" unless system( "which flac &> /dev/null" )

        # Compose the decode command
        flacDecodeCommand = Array.new
        flacDecodeCommand.push "flac"
        flacDecodeCommand.push "--silent"
        flacDecodeCommand.push "--decode"
        flacDecodeCommand.push "--stdout"
        flacDecodeCommand.push Shellwords.escape File.join( @base_directory, @relative_path )

        # Decode the FLAC file to WAV
        wavData = String.new
        IO.popen( flacDecodeCommand.join( " " ) ) do | io |
            wavData = io.read
        end

        return wavData
    end

    # Return parsed tags
    def tags

        # Check if metaflac exists
        raise "metaflac: Command not found" unless system( "which metaflac &> /dev/null" )

        # Parse tags
        @tags = Hash.new

        # Compose tag parsing command
        tagParseCommand = Array.new
        tagParseCommand.push "metaflac"
        tagParseCommand.push "--export-tags-to=-"
        tagParseCommand.push Shellwords.escape File.join( @base_directory, @relative_path )

        IO.popen( tagParseCommand.join( " " ) ) do | io |
            io.each_line do | line |
                tag = line.chomp.split "="
                @tags[ tag.at( 0 ).upcase ] = tag.at( 1 )
            end
        end

        # Use track number to handle disk numbers as well
        @tags[ "TRACKNUMBER" ] = @tags[ "TRACKNUMBER" ].to_i + 100 * @tags[ "DISCNUMBER" ].to_i unless @tags[ "TRACKNUMBER" ].nil?

        # Return tags
        return @tags
    end

    # Write out mp3 encoded version
    def to_mp3 mp3Path, artworkPath = ""
        # Check if flac exists
        raise "flac: Command not found" unless system( "which flac &> /dev/null" )

        # Check if lame exists
        raise "lame: Command not found" unless system( "which lame &> /dev/null" )

        # Ensure tags have been parsed
        self.parseTags

        # Compose the decode command
        flacDecodeCommand = Array.new
        flacDecodeCommand.push "flac"
        flacDecodeCommand.push "--silent"
        flacDecodeCommand.push "--decode"
        flacDecodeCommand.push "--stdout"
        flacDecodeCommand.push Shellwords.escape File.join( @base_directory, @relative_path )

        # Compose the encode command
        mp3EncodeCommand = Array.new
        mp3EncodeCommand.push "lame"
        mp3EncodeCommand.push "--silent"
        mp3EncodeCommand.push "--preset medium"
        mp3EncodeCommand.push "--id3v2-only"
        mp3EncodeCommand.push "--id3v2-latin1"
        mp3EncodeCommand.push "--tt #{Shellwords.escape @tags[ "TITLE" ]}"
        mp3EncodeCommand.push "--ta #{Shellwords.escape @tags[ "ARTIST" ]}"
        mp3EncodeCommand.push "--tl #{Shellwords.escape @tags[ "ALBUM" ]}"
        mp3EncodeCommand.push "--tn #{@tags[ "TRACKNUMBER"].to_i}" unless @tags[ "TRACKNUMBER" ].nil?
        mp3EncodeCommand.push "--tc #{Shellwords.escape @tags[ "COMMENT"]}"
        mp3EncodeCommand.push "--ty #{@tags[ "DATE"].to_i}" unless @tags[ "DATE" ].nil?
        mp3EncodeCommand.push "--tg #{Shellwords.escape @tags[ "GENRE"]}"
        mp3EncodeCommand.push "--ti #{Shellwords.escape artworkPath}" unless artworkPath.empty?
        mp3EncodeCommand.push "-"
        mp3EncodeCommand.push Shellwords.escape mp3Path

        # Encode the decoded FLAC file into MP3
        raise "Encoding media failed" unless system( "#{flacDecodeCommand.join( " " )} | #{mp3EncodeCommand.join( " " )}" )

        # Return the mp3 file path
        return mp3Path
    end
end


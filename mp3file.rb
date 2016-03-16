require_relative "mufile"

require "shellwords"

class MP3File < MuFile

    # Specify valid extensions
    @valid_extensions = [ ".mp3" ]

    # Specify error message
    @invalid_extension_message = "Invalid extension for MP3 file"

    # File need not exist
    @file_should_exist = false

    def set_tags inputTags
        @tags = inputTags
    end

    def set_artPath inputPath
        @artPath = inputPath
    end

    def from_wav wavData

        # Check if lame exists
        raise "lame: Command not found" unless system( "which lame &> /dev/null" )

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
        mp3EncodeCommand.push "--ti #{Shellwords.escape @artPath}" unless @artPath.nil?
        mp3EncodeCommand.push "-"
        mp3EncodeCommand.push Shellwords.escape File.join( @base_directory, @relative_path )

        # Encode the decoded FLAC file into MP3
        IO.popen( mp3EncodeCommand.join( " " ), "w" ) do | io |
            io.puts wavData
        end

        # Return the mp3 file path
        return File.join @base_directory, @relative_path
    end
end


require "shellwords"

class FlacFile
    def initialize path
        # Require that the filename end with the correct extension
        raise "Invalid FLAC filename" unless File.extname( path ).downcase == ".flac"

        # Require that the file exist
        raise "File not found" unless File.exist? path

        @flacPath = path
    end

    # Parse embedded tags in the flac file
    def parseTags
        # Check if metaflac exists
        raise "metaflac: Command not found" unless system( "which metaflac &> /dev/null" )

        # Parse tags
        @tags = Hash.new
        %x( metaflac --export-tags-to=- \""#{Shellwords.escape @flacPath}"\" ).each_line do | line |
            tag = line.chomp.split "="
            @tags[ tag.at( 0 ).upcase ] = tag.at( 1 )
        end
    end

    # Write out mp3 encoded version
    def to_mp3 mp3Path
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
        flacDecodeCommand.push Shellwords.escape @flacPath

        # Compose the encode command
        mp3EncodeCommand = Array.new
        mp3EncodeCommand.push "lame"
        mp3EncodeCommand.push "--silent"
        mp3EncodeCommand.push "--preset medium"
        mp3EncodeCommand.push "--id3v2-only"
        mp3EncodeCommand.push "--id3v2-utf16"
        mp3EncodeCommand.push "--tt #{Shellwords.escape @tags[ "TITLE" ]}"
        mp3EncodeCommand.push "--ta #{Shellwords.escape @tags[ "ARTIST" ]}"
        mp3EncodeCommand.push "--tl #{Shellwords.escape @tags[ "ALBUM" ]}"
        mp3EncodeCommand.push "--tn #{@tags[ "TRACKNUMBER"].to_i}"
        mp3EncodeCommand.push "--tc #{Shellwords.escape @tags[ "COMMENT"]}"
        mp3EncodeCommand.push "--ty #{@tags[ "DATE"].to_i}"
        mp3EncodeCommand.push "--tg #{Shellwords.escape @tags[ "GENRE"]}"
        mp3EncodeCommand.push "-"
        mp3EncodeCommand.push Shellwords.escape mp3Path

        # Encode the decoded FLAC file into MP3
        raise "Encoding media failed" unless system( "#{flacDecodeCommand.join( " " )} | #{mp3EncodeCommand.join( " " )}" )

        # Return the mp3 file path
        return mp3Path
    end
end


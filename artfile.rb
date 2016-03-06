require "shellwords"

class ArtFile
    def initialize path
        # Require that the filename end with either JPG or PNG
        raise "Invalid album art file name" unless [ ".jpg", ".jpeg", ".png" ].include? File.extname( path ).downcase

        @artPath = path
    end

    # Write out resized artwork
    def resize destination, dimensions
        # Require dimensions to be in ImageMagick-compatible format
        raise "Invalid size for resized artwork" unless dimensions =~ /\d*x\d*/

        # Require that artwork source file exist
        raise "File not found" unless File.exist? @artPath

        # Check if convert exists
        raise "convert: Command not found" unless system( "which convert &> /dev/null" )

        # Resize artwork
        artworkResizeCommand = Array.new
        artworkResizeCommand.push "convert"
        artworkResizeCommand.push "-resize #{dimensions}"
        artworkResizeCommand.push Shellwords.escape @artPath
        artworkResizeCommand.push Shellwords.escape destination

        raise "Resizing of artwork failed" unless system( artworkResizeCommand.join( " " ) )
    end
end


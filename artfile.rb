require_relative "mufile"

require "shellwords"

class ArtFile < MuFile

    # Specify valid extensions
    @valid_extensions = [ ".jpg", ".jpeg", ".png" ]

    # Specify error message
    @invalid_extension_message = "Invalid extension for artwork"

    # Write out resized artwork
    def resize destination, dimensions
        # Require dimensions to be in ImageMagick-compatible format
        raise "Invalid size for resized artwork" unless dimensions =~ /\d*x\d*/

        # Check if convert exists
        raise "convert: Command not found" unless system( "which convert &> /dev/null" )

        # Resize artwork
        artworkResizeCommand = Array.new
        artworkResizeCommand.push "convert"
        artworkResizeCommand.push "-resize #{dimensions}"
        artworkResizeCommand.push Shellwords.escape File.join( @base_directory, @relative_path )
        artworkResizeCommand.push Shellwords.escape destination

        raise "Resizing of artwork failed" unless system( artworkResizeCommand.join( " " ) )
    end
end


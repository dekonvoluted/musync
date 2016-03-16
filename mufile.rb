require_relative "fat32"

# Generic class for a file in a music library
class MuFile

    # Include ability to specify FAT32-safe version of path
    include FAT32

    # Set up class-instance variables for testing extensions
    def self.valid_extensions
        @valid_extensions = Array.new if @valid_extensions.nil?
        @valid_extensions
    end

    def self.invalid_extension_message
        @invalid_extension_message = "File extension is invalid" if @invalid_extension_message.nil?
        @invalid_extension_message
    end

    # Enable file existence check
    # Child classes may disable this
    def self.file_should_exist
        @file_should_exist = true if @file_should_exist.nil?
        @file_should_exist
    end

    # Initialize instance
    def initialize relativePath, baseDirectory = ""

        # Handle absolute paths gracefully
        if relativePath.start_with? "/"
            baseDirectory = "/"
            relativePath.gsub! /^\//, ""
        end

        # Sanitize base directory
        baseDirectory = File.realpath baseDirectory

        # Check if file exists
        if self.class.file_should_exist

            # Sanitize relative path
            relativePath = File.realpath relativePath, baseDirectory
            relativePath.gsub! /^#{baseDirectory}\/?/, ""
        end

        # Test if extensions are valid
        unless self.class.valid_extensions.empty?
            raise self.class.invalid_extension_message unless self.class.valid_extensions.include? File.extname relativePath
        end

        @base_directory = baseDirectory
        @relative_path = relativePath
    end

    # Return FAT32-safe version of relative path
    def safe_relative_path
        FAT32.safepath @relative_path
    end

    # Return full path
    def path
        File.join @base_directory, @relative_path
    end
end


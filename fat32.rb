module FAT32
    # Create FAT32-safe file/directory names
    def self.safeName badName
        # Avoid strings longer than 240 characters (with .mp3 extension)
        goodName = badName.slice( 0, 236 )

        # Allow only safe characters
        badCharacters = /[^a-zA-Z0-9\.\-\ ]/
        goodName.gsub! badCharacters, "_"

        # Avoid leading/trailing spaces or dots
        goodName.gsub! /^\s/, "_"
        goodName.gsub! /\s$/, "_"
        goodName.gsub! /^\./, "_"
        goodName.gsub! /\.$/, "_"

        # Avoid empty or "." file names
        goodName = "empty" if goodName.empty?
        goodName = "dot" if goodName == "."

        return goodName
    end
end


module FAT32
    # Return FAT32-safe string
    def self.safename badName
        # Avoid strings longer than 240 characters
        goodName = badName.slice( 0, 240 )

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

    # Return FAT32-safe path
    def self.safepath badPath
        safePath = badPath.split "/"
        safePath.map! do | dir |
            safename dir
        end

        return safePath.join "/"
    end
end


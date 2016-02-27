# Create FAT32-safe file/directory names
def getFAT32SafeName badName
    # Avoid strings longer than 240 characters (with .mp3 extension)
    safeName = badName.slice( 0, 236 )

    # Allow only safe characters
    badCharacters = /[^a-zA-Z0-9\.\-\ ]/
    safeName.gsub! badCharacters, "_"

    # Avoid leading/trailing spaces or dots
    safeName.gsub! /^\s/, "_"
    safeName.gsub! /\s$/, "_"
    safeName.gsub! /^\./, "_"
    safeName.gsub! /\.$/, "_"

    # Avoid empty or "." file names
    safeName = "empty" if safeName.empty?
    safeName = "dot" if safeName == "."

    return safeName
end



#!/usr/bin/env ruby

# Transcode a FLAC library into MP3
# Keep libraries in sync
# Keep MP3 library file names FAT32-compatible

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

# Test safe FAT32 names function
def testFAT32SafeNames
    testStrings = Array.new
    expectedResults = Array.new

    # Test a simple string
    testStrings.push     "This is a safe string"
    expectedResults.push "This is a safe string"

    # Test special characters
    testStrings.push     "[\\/:*?\"<>|,.]&"
    expectedResults.push "___________.__"

    # Test long strings
    testStrings.push "This is a string that is simply too long and will need to be truncated to fit within the 240 character limit if it is to be considered safe for the File Allocation Table 32 bit file system that was all the rage back in the day when such things were common"
    expectedResults.push "This is a string that is simply too long and will need to be truncated to fit within the 240 character limit if it is to be considered safe for the File Allocation Table 32 bit file system that was all the rage back in the day when such"

    # Test leading/trailing spaces or dots
    testStrings.push     " leading space trailing space "
    expectedResults.push "_leading space trailing space_"

    testStrings.push ".leading dot trailing dot."
    expectedResults.push "_leading dot trailing dot_"

    # Compare expectations with actual output
    testStrings.each_with_index do | value, index |
        if getFAT32SafeName( value ) != expectedResults.at( index )
            puts "Failed:"
            puts "Input: #{value}"
            puts "Expected: #{expectedResults.at( index )}"
            puts "Actual: #{getFAT32SafeName( value )}"
        else
            puts "Passed."
        end
    end
end

testFAT32SafeNames


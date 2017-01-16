## TODO list

- Do a menu to choose categories from, rather than having to specify the ID number(s)<a name="catById"></a>
- Paginate for all lookup types; currently only doing it for `Search-Api` and `Get-VideosFromCategory`
- Show estimates for download times:
    - Might not be possible with the BITS command currently in use
    - Maybe just calculate these based on 5/10/15 Mbps to give a broad sense of timing
- Get a direct download link for the Jeff Error video file, because:
    - I know I lean on it a lot when I'm developing this monstrosity
    - The script basically won't work if you don't have a local copy, since it references the size and timestamp properties on the file
- Show the overall time taken to download
- Put a wrapper around Invoke-WebRequest to combine the 1 second sleep into one call, rather than having to remember to add the sleep line every time
- Write some more Pester tests to cover this whole mess
- Double check the sort order of the converted videos list
- Set the created date of files to the publish date of the video

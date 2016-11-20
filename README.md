# Giant Bomb dot com and PowerShell, together at last
## Purpose

I've been using PowerShell more and more over the past few years, and I've been a [Giant Bomb][gb] fan for even longer. It's high time they got together, and this collection of scripts is a direct result of that most unholy of unions.

For real though, I wrote something very similar to this years ago in [bash][bash], so that I could download GB videos and copy them onto my phone, to watch while commuting, traveling, etc. Over the last few months I've been rebuilding most of the logic and functionality from that original script in PowerShell.

This script does the following:

1. Interrogates the [Giant Bomb API][gbapi] via a few different methods:
    - Choosing a video category ([by ID, for the moment](#catById)).
    - Supplying an [RSS feed URL][gbrss]:
        - Note that not all feed types have been tested or even attempted yet.
        - I have only been using `http://www.giantbomb.com/feeds/video/`.
    - Supplying a URL for [a game page on the GB wiki][gbgames].
    - Search using keyword(s).
    - Suppyling a URL for a single video:
        - e.g. `http://www.giantbomb.com/videos/quick-look-watch-dogs-2/2300-11716/`
1. Builds up a list of videos in the specified scope(s).
1. Steps through the list confirming whether or not the user wants to download each video found.
1. Gets the HD version of the video(s) that the user wants.

**Beware:** I have not taken non-premium users into consideration with this script.

Part of what I want to get out of this project, and most especially from sharing it on GitHub, is some education on best practices in general and also better ways to modularise and structure the code more effectively and efficiently.

## Current features and functionality

- Download HD videos from Giant Bomb, based on any of the following inputs
    - Search term
    - Game name/link
    - Specific video page link
    - Video category by ID#
    - RSS feed
- Always waits 1 second after every API request (rate limit)
- Handles errors gracefully and in a reasonable manner
    - The Jeff Error, caused by too many video download requests too quickly
    - Filenames with square brackets
    - Videos that don't give back HD URLs from the API
- Processes oldest videos first, newest last
- Only prompts once to download a video
    - If the user doesn't want a video once, doesn't ask about it again
- Does all of the prompting first, and only starts downloading after all prompts are exhausted
- Video names which have characters that are invalid for filenames are scrubbed
- Downloads to `$($env:HOME)\Videos\Giant Bomb\` with sub-directories for different video types/categories
    - Creates sub-directory hierarchy if it doesn't already exist
- Runs a timer on downloads and shows how long each one took
- Keeps a running count of bytes downloaded
- Handles pagination accordingly, as some API result sets span multiple pages

## TODO list

- Put in parameter handling for the video search scope, instead of editing the script file directly.
- Do a menu to choose categories from, rather than having to specify the ID number(s).<a name="catById"></a>
- Paginate for all lookup types; currently only doing it for `Search-Api` and `Get-VideosFromCategory`.
- Needs to handle the following:
    - Empty URLs from the API e.g. the botched Gears 4 QL:
        - `http://www.giantbomb.com/videos/quick-look-gears-of-war-4/2300-11632/`
    - Filenames with square brackets:
        - `http://www.giantbomb.com/videos/the-witcher-3-blood-and-vino/2300-11206/`
- Show estimates for download times:
    - Might not be possible with the BITS command currently in use.
    - Maybe just calculate these based on 5/10/15 Mbps to give a broad sense of timing.
- Get a direct download link for the Jeff Error video file, because:
    - I know I lean on it a lot when I'm developing this monstrosity.
    - The script basically won't work if you don't have a local copy, since it references the size and timestamp properties on the file.
- Show the overall time taken to download.

[gb]: http://www.giantbomb.com
[bash]: https://en.wikipedia.org/wiki/Bash_%28Unix_shell%29
[gbapi]: http://www.giantbomb.com/api/
[gbrss]: http://www.giantbomb.com/feeds/
[gbgames]: http://www.giantbomb.com/games/

# Giant Bomb dot com and PowerShell, together at last
## Purpose

I've been using PowerShell more and more over the past few years, and I've been a [Giant Bomb][gb] fan for even longer. It's high time they got together, and this collection of scripts is a direct result of that most unholy of unions.

Legitimately though, I wrote something very similar to this years ago in [bash][bash], so that I could download GB videos and copy them onto my phone, to watch while commuting, traveling, etc.

I've been rebuilding most of the logic and functionality from that original bash script in PowerShell.

This script does the following:

1. Interrogates the [Giant Bomb API][gbapi] via a few different methods
    - Choosing a video category ([by ID, for the moment](./TODO.md#catById))
    - Accessing an [RSS feed URL][gbrss]
        - Note that not all feed types have been tested or even attempted yet
        - Currently hard-coded to `http://www.giantbomb.com/feeds/video/`
    - Supplying a URL for [a game page on the GB wiki][gbgames]
    - Searching with keyword strings
    - Supplying a URL for a single video
        - e.g. `http://www.giantbomb.com/videos/quick-look-watch-dogs-2/2300-11716/`
    - Iterating through _all_ of the videos
1. Builds up a list of videos in the specified scope(s)
1. Steps through the list confirming whether or not the user wants to download each video found
1. Creates/downloads a file locally
    - HD versions of the videos that the user wants
    - Empty dummy copies with some metadata, of the videos that the user does not want

**Beware:** I have not taken non-premium users into consideration with this script.

Part of what I want to get out of this project, and most especially from sharing it on GitHub, is some education on best practices in general and also better ways to modularise and structure the code more effectively and efficiently.

## Current features and functionality

- Downloads HD videos from Giant Bomb, based on any of the following inputs
    - Search term
    - Game name/link
    - Specific video page link
    - Video category by ID#
    - RSS feed
    - The master list of videos
- Always waits 1 second after every API request (rate limit)
- Handles errors gracefully and in a reasonable manner
    - The Jeff Error, caused by too many video download requests in a 24 hour period
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

## API authentication

The script will give you a somewhat reasonable error if you don't do this, but I'm adding it here anyway.

There is a JSON file named `GiantBombApiKey.example.json` that needs to be duplicated and renamed to `GiantBombApiKey.json` with a valid key edited into it.

This file is of course in .gitignore already, so don't worry about checking it in accidentally.

[gb]: http://www.giantbomb.com
[bash]: https://en.wikipedia.org/wiki/Bash_%28Unix_shell%29
[gbapi]: http://www.giantbomb.com/api/
[gbrss]: http://www.giantbomb.com/feeds/
[gbgames]: http://www.giantbomb.com/games/

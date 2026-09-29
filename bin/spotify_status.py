#!/usr/bin/env python3
"""Get the current playing song from Spotify using playerctl."""

import subprocess
import sys
import argparse


def get_spotify_status():
    """Get the current Spotify status."""
    try:
        # Get the status
        status = subprocess.run(
            ["playerctl", "--player=spotify", "status"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if status.returncode != 0:
            return ""
        
        current_status = status.stdout.strip().lower()
        
        # Get metadata
        metadata = subprocess.run(
            ["playerctl", "--player=spotify", "metadata", "--format", "{{artist}} - {{title}}"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if metadata.returncode != 0:
            return ""
        
        song_info = metadata.stdout.strip()
        
        if not song_info:
            return ""
        
        # Add status icon
        if current_status == "playing":
            return f" {song_info}"
        elif current_status == "paused":
            return f" {song_info}"
        else:
            return ""
            
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        return ""


def main():
    parser = argparse.ArgumentParser(description="Get Spotify status")
    parser.add_argument(
        "-f", "--format",
        default="{song}",
        help="Format string. Use {song} for song info, {status} for status"
    )
    args = parser.parse_args()
    
    status = get_spotify_status()
    
    if status:
        print(args.format.format(song=status, status="playing"))
    else:
        print("")


if __name__ == "__main__":
    main()

# Summarize YouTube Video

Summarize a YouTube video using the bash_summarize_yt tool located at `/Users/zev/repos/bash_summarize_yt`.

## Variables

youtube_url: $1

## Instructions

1. If no URL is provided ($1 is empty), ask the user to provide a YouTube URL
2. Run the summary script: `cd /Users/zev/repos/bash_summarize_yt && ./summ.sh "$youtube_url"`
3. The script will:
   - Extract the video transcript
   - Save it to `~/.bash_summarize_yt/yt_transcripts/`
   - Generate a summary using Claude
   - Save the summary to `~/.bash_summarize_yt/yt_summaries/`
4. If the script's Claude integration fails (API issues), read the transcript file and generate a summary manually
5. Display the summary to the user
6. Let the user know where the files are saved

## Notes

- Summaries are cached - if you summarize the same video twice, it will use the cached version
- The tool stores transcripts, basic summaries, and detailed summaries
- Location: `~/.bash_summarize_yt/`
  - `yt_transcripts/` - raw transcripts
  - `yt_summaries/` - markdown summaries
  - `yt_detailed_summaries/` - detailed versions

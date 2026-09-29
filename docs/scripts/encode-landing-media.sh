#!/bin/zsh
# Rebuild landing-page media from the screen recordings in ~/Movies.
# Keeps the source frame size. Drops silent audio, 30 fps, H.264 faststart.
# Grid hovers use a 960-wide 60 fps H.264; the full-frame mp4 plays on click.
set -euo pipefail

src="${1:-$HOME/Movies}"
out="${2:-$(cd "$(dirname "$0")/.." && pwd)/public/media}"
mkdir -p "$out"

encode() {
  local input="$1" name="$2" motion="$3" audio="$4"
  echo "encoding $name"
  if [[ "$audio" == "copy" ]]; then
    ffmpeg -y -hide_banner -loglevel error -i "$input" \
      -map 0:v:0 -map 0:a:0 -c:v libx264 -preset medium -crf 26 -pix_fmt yuv420p -r 30 \
      -profile:v high -g 90 -movflags +faststart -c:a copy \
      "$out/$name.mp4"
  else
    ffmpeg -y -hide_banner -loglevel error -i "$input" \
      -map 0:v:0 -an -c:v libx264 -preset medium -crf 26 -pix_fmt yuv420p -r 30 \
      -profile:v high -g 90 -movflags +faststart \
      "$out/$name.mp4"
  fi
  ffmpeg -y -hide_banner -loglevel error -ss 0.4 -i "$input" -frames:v 1 \
    -vf "scale=1600:-2:flags=lanczos" -c:v libwebp -quality 72 \
    "$out/$name.webp"
  if [[ "$motion" == "1" ]]; then
    ffmpeg -y -hide_banner -loglevel error -i "$input" -an \
      -vf "scale=960:-2:flags=lanczos" -c:v libx264 -preset fast -crf 26 -pix_fmt yuv420p -r 60 \
      -g 60 -movflags +faststart \
      "$out/$name-hover.mp4"
  fi
}

encode "$src/Inbox review.mp4" inbox-review 0 strip
encode "$src/Agent conversation.mp4" agent-conversation 1 strip
encode "$src/PR Diff.mp4" pr-diff 1 strip
encode "$src/Tickets.mp4" tickets 1 strip
encode "$src/Meetings.mp4" meetings 1 strip
encode "$src/Pipelines.mp4" pipelines 1 strip
encode "$src/Soundscape.mp4" soundscape 1 copy
encode "$src/Usage subscription.mp4" usage-subscription 1 strip
encode "$src/Account switching.mp4" account-switching 1 strip
encode "$src/AI review.mp4" ai-review 1 strip
encode "$src/Observability.mp4" observability 1 strip
encode "$src/Parallel agents.mp4" parallel-agents 1 strip
encode "$src/Pipeline templates.mp4" pipeline-templates 1 strip
encode "$src/Agents and skills.mp4" agents-and-skills 1 strip
encode "$src/Agent permissions.mp4" agent-permissions 1 strip

echo
ls -lh "$out"/*.{mp4,webp}

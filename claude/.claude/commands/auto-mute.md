# Auto-Mute Voice

Toggle auto-mute on the PAI voice server. When enabled, voice only plays when 2+ concurrent Claude Code sessions are detected.

If "$ARGUMENTS" is "on", enable auto-mute. If "off", disable it. If empty, toggle.

```bash
# Map argument to enabled value
ARG="$ARGUMENTS"
if [ "$ARG" = "on" ]; then
  curl -sX POST http://localhost:8888/auto-mute -H 'Content-Type: application/json' -d '{"enabled":true}'
elif [ "$ARG" = "off" ]; then
  curl -sX POST http://localhost:8888/auto-mute -H 'Content-Type: application/json' -d '{"enabled":false}'
else
  curl -sX POST http://localhost:8888/auto-mute
fi
```

Report the result to the user including current session count and threshold.

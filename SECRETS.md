# Secrets — to move to new machine

## Key files (mode 600)

| Path | Description |
|---|---|---|
| `~/.openai_key` | OpenAI API key |
| `~/.gitlab-token` | GitLab PAT |
| `~/.hugginface_token` | HF token |
| `~/.yc-cli-key` | Yandex Cloud CLI key |
| `~/.claude.json` | Claude CLI config with MCP tokens |
| `~/.hammerspoon_local.lua` | Hammerspoon private values (`ZOOM_MEETING_URL` alt-a z, `STREAM_ROOM_URL` alt-a k) |

## getting secrets
```bash
# General pattern
umask 077
bw get password <bw-item> > ~/.openai_key
chmod 600 ~/.openai_key
# and so on
```

# Env values (in `~/.zshrc.secret`)
For any other 'KEY=secret'-like in the env secrets

Use the `~/.zshrc.secret` file

### ~/.hammerspoon_local.lua example

```lua
-- Private Hammerspoon values (not in dotfiles repo). Loaded by modules/modes/app_launch.lua.
return {
  -- Fill in: Zoom app -> Meetings -> Personal Meeting ID -> "Copy invitation",
  -- take the https://…zoom.us/j/<id>?pwd=<pwd> link. Never commit the real one.
  ZOOM_MEETING_URL = "https://<subdomain>.zoom.us/j/<meeting-id>?pwd=<passcode>",
}


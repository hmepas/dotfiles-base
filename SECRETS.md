# Secrets — to move to new machine

## Key files (mode 600)

| Path | Description |
|---|---|---|
| `~/.openai_key` | OpenAI API key |
| `~/.gitlab-token` | GitLab PAT |
| `~/.hugginface_token` | HF token |
| `~/.yc-cli-key` | Yandex Cloud CLI key |
| `~/.claude.json` | Claude CLI config with MCP tokens |

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

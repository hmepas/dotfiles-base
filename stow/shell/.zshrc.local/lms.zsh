# LM Studio CLI (lms): same location on Mac and Linux; no-op where not installed.
if [ -d "$HOME/.lmstudio/bin" ]; then
  export PATH="$PATH:$HOME/.lmstudio/bin"
fi

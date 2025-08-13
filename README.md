# Ottotext (iOS)

Ottoman text converter chat app for iPhone. Simple bot UI (like Zchat): you type Turkish, it returns Ottoman Arabic script using Google Gemini 2.5 Pro.

Features
- Minimal chat UI (monospace green on black)
- Calls Gemini 2.5 Pro over HTTPS (no SDK)
- Temperature 0.0 for deterministic output
- Optional knowledgebase text bundled (you can replace `Resources/ottoman.txt`)
- API key prompt stored locally for development

Setup
```bash
# Generate Xcode project (uses XcodeGen)
brew install xcodegen
cd ottotext
xcodegen generate
open Ottotext.xcodeproj
```

In Xcode:
- Targets → Ottotext → Signing: set your Team and a unique Bundle Identifier
- Run on a device or simulator

API key
- On first run, tap the key icon to paste your Google Gemini API key (from Google AI Studio)
- You can also set it in scheme environment `GEMINI_API_KEY`

Replace bundled knowledgebase
- Put your guidance in `Resources/ottoman.txt` (UTF‑8 text). The app sends the start of this file along with your message.

Security
- Do not ship your personal API key in production. Use a server‑side proxy for production apps.

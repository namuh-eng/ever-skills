# Ever Skills

Community-shared skill recipes for the [Ever CLI](https://foreverbrowsing.com) — an autonomous web agent that controls your browser.

## What is this?

Skills are reusable recipes you can run with the Ever CLI. Each skill folder contains:
- A `SKILL.md` — describes what the skill does and how to invoke it
- A `recipes/` folder — JavaScript/TypeScript files you can run via `ever eval`

## Installing the Ever Chrome Extension

Ever is not yet listed on the Chrome Web Store. Install it manually:

### Step 1 — Download the extension

> **Note:** The extension bundle is currently being prepared and will be uploaded to the [releases page](https://github.com/namuh-eng/forever-agent/releases) soon. Check back shortly!

Download the latest `.zip` from the [Ever releases page](https://github.com/namuh-eng/forever-agent/releases) and unzip it.

### Step 2 — Load in Chrome

1. Open Chrome and go to `chrome://extensions`
2. Enable **Developer mode** (toggle in the top-right corner)
3. Click **Load unpacked**
4. Select the unzipped extension folder

The Ever icon will appear in your Chrome toolbar.

### Step 3 — Sign in

Click the Ever icon to open the side panel and sign in with Google at [foreverbrowsing.com](https://foreverbrowsing.com).

### Step 4 — Install the CLI

```bash
npm install -g @ever/cli
```

Verify it's working:

```bash
ever --version
ever start --url https://example.com
ever snapshot
```

---

## Available Skills

| Skill | Description |
|-------|-------------|
| [ever-browser](./ever-browser/) | Browser control commands and workflows for the Ever CLI |

---

## Contributing

Have a useful skill or recipe? Open a PR and add it as a new folder under the skill name.

```
your-skill/
├── SKILL.md          # Description and usage
└── recipes/
    └── your-recipe.js
```

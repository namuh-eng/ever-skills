# Ever Skills

Community-shared skill recipes for the [Ever CLI](https://foreverbrowsing.com) — an autonomous web agent that controls your browser.

## What is this?

Skills are reusable recipes you can run with the Ever CLI. Each skill folder contains:
- A `SKILL.md` — describes what the skill does and how to invoke it
- A `recipes/` folder — JavaScript/TypeScript files you can run via `ever eval`

---

## Installing the Ever Chrome Extension

### Step 1 — Download the zip

Go to the [latest release](https://github.com/namuh-eng/ever-skills/releases/latest) and download `everextension-0.1.0-chrome.zip`.

### Step 2 — Unzip it

Unzip the file anywhere on your computer. You'll get a folder with the extension files inside.

```bash
unzip everextension-0.1.0-chrome.zip -d ever-extension
```

### Step 3 — Load in Chrome

1. Open Chrome and navigate to `chrome://extensions`
2. Enable **Developer mode** using the toggle in the top-right corner
3. Click **Load unpacked**
4. Select the unzipped `ever-extension` folder

The Ever icon will appear in your Chrome toolbar. Your extension ID will be stable across reinstalls.

### Step 4 — Sign in

Click the Ever icon → the side panel opens → sign in with Google.

### Step 5 — Install the CLI (optional)

```bash
npm install -g @ever/cli
```

Verify:

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

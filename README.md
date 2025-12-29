# iMessage Wrapped 📱✨

![iMessage Wrapped Hero](hero_banner.jpg)

> **"Turn your iMessage history into a beautiful, shareable 'Wrapped' experience with private, on-device AI analytics."**

[![macOS](https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

## Why iMessage Wrapped?

Ever wondered who you actually talk to the most? Or if you're *really* the one initiating all the conversations? **iMessage Wrapped** gives you the deep insights Apple won't.

- 🔒 **100% Private**: Everything runs locally on your Mac. Your data never leaves your device.
- 🧠 **AI-Powered**: Uses on-device AI to analyze sentiment, communication styles, and relationship dynamics.
- 🎨 **Beautiful Design**: A premium, "Spotify Wrapped" style experience with smooth animations and dark mode aesthetics.

## Features that WOW 🤩

### 📊 Deep Analytics
*   **Top Contacts Leaderboard**: See who made the cut.
*   **Messaging Patterns**: Discover your peak texting hours and busiest days.
*   **Emoji Analysis**: Your signature emojis revealed.

### 🧠 AI Insights & "Communication DNA"
*   **Personality Profiling**: Are you a "Night Owl", "The Novelist", or a "dry texter"?
*   **Relationship Dynamics**: unique archetypes like "The Chaser", "Soulmate Material", or "Trauma Bonding".
*   **Ghosting Events**: See who ghosted who (and when you reconnected).
*   **Topic Universes**: See what you actually talk about (Food 🍕, Work 💼, Drama 😭).

### 📖 Narrative Journeys
*   **Year in Review**: A personalized story of your year in texts.
*   **Emotional Journey**: How your conversations evolved over time.

## 🧠 How it Works

*   **Private & Local**: Reads your local `chat.db` directly. No data ever leaves your Mac.
*   **Apple Intelligence**: Uses Apple's on-device `NaturalLanguage` framework for sentiment analysis and linguistic tagging.
*   **Zero Setup**: No API keys, no cloud servers, no downloads. Just drag and drop.

## 💻 System Requirements

*   **OS**: macOS 14.0 (Sonoma) or later.
*   **Chip**: Apple Silicon (M1+) recommended for best performance.
*   **Permissions**: Full Disk Access (required to read `chat.db`).

## 🚀 Get the App

Visit the **[Landing Page](https://www.andreilyskov.com/iMessage-Wrapped/)** to download the latest **.dmg** for macOS.

### Important: Permissions
Because your messages are private, macOS protects them. You must grant the app permission to read them:

1.  Open **System Settings**.
2.  Go to **Privacy & Security** > **Full Disk Access**.
3.  Click the `+` button and add **iMessage Wrapped**.
4.  Restart the app.

> [!NOTE]
> If you don't do this, the app will show an error saying it can't find your message database.

## 🛠️ Build from Source

If you prefer to build it yourself:

1.  Clone the repo:
    ```bash
    git clone https://github.com/Andreilys/iMessage-Wrapped.git
    ```
2.  Open `iMessageWrapped.xcodeproj` in Xcode 15+.
3.  Press **Cmd + R** to build and run.



## License

MIT License. Built with ❤️ for data nerds.

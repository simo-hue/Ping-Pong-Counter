# 🏓 Ping Pong Counter

[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0%2B%20%7C%20watchOS%2010.0%2B-blue?style=for-the-badge&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.badge.dog/v1/language/swift/6.0.svg?style=for-the-badge)](https://developer.apple.com/swift/)
[![App Store](https://img.shields.io/badge/App_Store-Coming_Soon-black?style=for-the-badge&logo=app-store)](https://www.apple.com/app-store/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Ever played a fierce, sweat-inducing match of Table Tennis, only to pause midway because neither you nor your opponent could remember the score?** 

We've all been there. Argued about who was serving, whether it was `8-7` or `9-6`, and had the rhythm of an amazing game ruined. 

**Ping Pong Counter** is the ultimate, premium companion app for iPhone and Apple Watch designed to solve this exact problem forever. Crafted with high-end dark aesthetics, glowing neon scoring fields, and modern Apple APIs, it turns scorekeeping into a fluid, responsive, and gorgeous part of the sport.

---

## 🔗 Try It Out!

* 🌐 **Official Website:** [pingpongcounter.com](https://pingpongcounter.com) *(Coming Soon)*
* 🎬 **Live Web Demo & Walkthrough:** [demo.pingpongcounter.com](https://demo.pingpongcounter.com)
* 📲 **Download on the App Store:** 
  
  [![Download on the App Store](https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg)](https://apps.apple.com/app/ping-pong-counter)

---

## ✨ Features

### 📱 1. iPhone Full-Screen Scoreboard
* **Responsive OLED Neon Layout:** Designed to look stunning on Retina screens. Support for both **horizontal** (split screen left/right for tabletop use) and **vertical** orientations (split screen top/bottom for quick one-handed use).
* **Zero-Interference Gesti-Controls:**
  * **Tap to Score (`+1`):** Simple tap on either side registers a point instantly. Includes a dynamic floating `+1` pop animation.
  * **Swipe Down to Undo (`-1`):** Made a mistake? Swipe down on the player's field to reverse the last action. Holds up to 30 steps of rollback history.
* **Breathing Serve Pulse:** A continuous scale-and-glow loop indicator on the serving side, so you always know who has the ball.

### ⌚ 2. Native Apple Watch Companion
* **Hands-Free Scoring:** Leave your iPhone on a tripod at the net. Keep score directly from your wrist.
* **Instant Bidirectional Sync:** Built on high-performance `WatchConnectivity`. Tapping your watch updates your iPhone in real-time, and vice-versa.
* **Wrist Gestures:** Tap a player column to add a point, long-press to undo.

### ⚡ 3. Live Activities & Dynamic Island
* **Lock Screen Tracking:** Lock your phone and save battery. The live score, set count, and active server are projected directly onto your **Lock Screen** widget in real-time.
* **Dynamic Island Integration:** Minimizes into a beautiful, compact pill on the home screen showing live points, expanding on long-press into a glassmorphic dashboard.

### 🔊 4. Premium Extras
* **Vocal Referee (Speech Synthesis):** Native Italian/English umpire voices that announce scores and critical moments (*"Match Point!"*, *"Set Point!"*, *"Deuce!"*).
* **Audio Session Ducking:** Automatically lowers background music volume when announcing the score and restores it immediately after.
* **Tactile Haptic Feedback:** Customized vibration signatures for standard points, serve rotations, and match wins using Apple's Taptic Engine.
* **Smart UserDefaults Persistence:** Remembers all your custom rules, player names, sound settings, and active color themes across launches.

---

## 🛠️ Official Game Rules Compliance
Designed in strict accordance with the **ITTF (International Table Tennis Federation)** standards:
* Supports standard **11-point** games or classic **21-point** formats.
* Smart serve rotation: automatically switches every **2 serves** (for 11-point games) or every **5 serves** (for 21-point games).
* Automatic **Deuce (Vantaggi)** handling: once the score reaches `10-10`, the serve rotation automatically switches to **1 serve per player** until one player leads by 2 points.

---

## 🎨 Creative Themes
Choose between three professionally curated high-contrast glowing neon schemes in the Settings sheet:
* 🔴🔵 **Classic Neon:** Hot Pink & Cyan Blue (Default)
* 🟢🟣 **Mint & Royal:** Mint Green & Deep Purple
* 🟠🟢 **Solar Flare:** Solar Orange & Teal Green

---

## 💻 Tech Stack
* **Core Framework:** SwiftUI (iOS 17.0+ / watchOS 10.0+)
* **State Management:** Combine & `@MainActor` MVVM Architecture
* **Background Sync:** ActivityKit (Live Activities) & WatchConnectivity
* **Audio Engine:** AVFoundation (`AVSpeechSynthesizer` & `AVAudioSession`)
* **Persistence:** Foundation `UserDefaults` persistence
* **Haptics:** `UIImpactFeedbackGenerator`

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*Created with 🏓 by Simo. Happy playing!*

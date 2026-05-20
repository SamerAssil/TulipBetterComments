# TulipBetterComments

A Delphi IDE plugin that enhances code readability by colorizing comments dynamically based on specific prefixes. 

## Features

The plugin intercepts the IDE's text paint events to apply custom colors to single-line comments without altering the actual syntax highlighter. 


<img width="560" height="116" alt="Screenshot 2026-05-20 at 20 33 16" src="https://github.com/user-attachments/assets/2aede877-f17c-42bc-ad5b-288c4daa83c2" />

Supported prefixes:
* `//*` - Renders in **Red** (Ideal for critical notes, bugs, or errors).
* `//!` - Renders in **Orange** (Ideal for warnings or important alerts).
* `//?` - Renders in **Blue** (Ideal for questions, to-dos, or reviews).

## Compatibility

* **Requires Delphi 11 Alexandria or newer.**
* Not compatible with older versions of RAD Studio.

## Installation

1. Clone or download this repository.
2. Open the package file (`.dpk` or `.dproj`) in your Delphi IDE.
3. Right-click the package in the **Project Manager** and select **Build**.
4. Right-click the package again and select **Install**.
5. Restarting the IDE is not required; the effect is applied immediately to open editor tabs.

## Usage Example

Simply type the designated prefixes at the start of your comments inside the code editor:

```pascal
// Standard Delphi comment (IDE default color)
//* Critical logic block - Do not modify (Red)
//! Deprecated method used here (Orange)
//? Needs refactoring in the next release (Blue)
```

## Roadmap (Future Plans)
- [ ] Settings Dialog: Add an options window within the IDE Tools menu for easy configuration.
- [ ] Custom Tokens & Colors: Allow users to add new custom prefix symbols and assign custom colors to them, extending beyond the default three options.

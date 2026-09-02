---
name: visual-matrix
description: Screenshot every stage-visible state of the app after a visual change and look at every image. Use after editing any .html, .css or renderer file, and before claiming a visual change is done.
effort: medium
---
1. Find the repo's screenshot tool, in this order: `tests/shot-matrix.js`, `scripts/shots.mjs`, `tools/shoot.mjs`, a Playwright config, else write a one-off Playwright script using the Chromium already installed.
2. Run it. Cover both viewports (1920x1080 and 390x844), every theme or ground the app has (night and day, dark and light), every mode (stack and round, and so on) and any exported file re-opened in a browser. The states that were not changed this session matter most; that is where the last week of defects lived.
3. Hand the images to the freezemag-base screenshot-auditor agent. It looks at every image and lists defects with the file and line that likely causes each. You do not skip images.
4. Say what you checked and what looked wrong, in that order. A count of screenshots is not a result. "Looks a bit off" means it is off: investigate.

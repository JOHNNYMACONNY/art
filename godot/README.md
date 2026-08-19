# Godot 4.7 Desktop Golden Block Prototype

This directory contains the Godot 4.7 Desktop Golden Block prototype for evaluating high-end Desktop/Steam release targets.

## Scope
- 1 Street / Scrap Yard section of Gears District
- On-foot movement & shooting
- Vehicle driving mechanics
- Police pursuit response
- FB-13 Thrum & HS-7 Wavicle visual/audio FX
- Desktop native Audio Engine comparison

## Browser playtest

GitHub Actions exports the project with the `Web Playtest` preset. The CI job builds an isolated WebGL/Compatibility copy, smoke-tests the generated static bundle, and uploads the browser-ready build as an artifact. The source project remains configured for its desktop Forward+ target.

For an explicit ChatGPT-driven verification pass, comment `/playtest` on an open pull request. The workflow builds that PR's current head and reports PASS/FAIL back to the PR conversation.

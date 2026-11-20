#!/usr/bin/env python3
"""Experimental real-Chromium keyboard session against the exported Godot Web game.

This is browser input and actual canvas-frame evidence, not subjective listening.
Never promotes unapproved recorded audio or asserts game quality from CI alone.
"""
from __future__ import annotations

import argparse
import http.server
import json
import shutil
import threading
import time
from pathlib import Path

from PIL import Image, ImageChops
from playwright.sync_api import sync_playwright


class IsolatedHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, *_args):
        return


def frame_change(a: Path, b: Path) -> dict:
    with Image.open(a) as first, Image.open(b) as second:
        a_rgb = first.convert("RGB")
        b_rgb = second.convert("RGB")
        if a_rgb.size != b_rgb.size:
            raise RuntimeError("Canvas dimensions changed during keyboard session")
        width, height = a_rgb.size
        center = (width // 5, height // 6, width * 4 // 5, height * 5 // 6)
        delta = ImageChops.difference(a_rgb.crop(center), b_rgb.crop(center))
        histogram = delta.convert("L").histogram()
        pixels = sum(histogram)
        changed = sum(histogram[12:])
        return {"changed_center_ratio": round(changed / max(1, pixels), 6), "pixels": pixels}



def visually_inspect_action_label(screenshot: Path) -> dict:
    """Conservative screenshot-only hint for the 960x540 diagnostic HUD.

    These bounds come from inspected real Chromium captures: a highlighted
    [E] RIDE BIKE label has a narrower bright-green glyph band than the
    longer [E] DRIVE COUPE / HAULER labels. This is NOT OCR, a gameplay
    state query, or authoritative evidence of mounting. Unknown layouts and
    low-confidence highlights must return "unknown".
    """
    with Image.open(screenshot) as original:
        image = original.convert("RGB")
        if image.size != (960, 540):
            return {"hint": "unknown", "reason": "unexpected_capture_resolution", "size": list(image.size)}
        lit = []
        for y in range(444, 488):
            for x in range(782, 944):
                r, g, b = image.getpixel((x, y))
                if g > 60 and g > r * 1.35 and g > b * 1.02:
                    lit.append((x, y))
    if not lit:
        return {"hint": "unknown", "green_pixels": 0}
    width = max(x for x, _ in lit) - min(x for x, _ in lit) + 1
    count = len(lit)
    # Based on separately inspected, real 960x540 frames: the highlighted
    # [E] PEEL PANEL glyph spans ~114 px / 690 green pixels; the bike
    # spans ~97 px / 647 pixels. Neither hint proves the in-game action.
    hint = "other_or_unhighlighted"
    if 88 <= width <= 107 and 450 <= count <= 730:
        hint = "possible_courier_action"
    elif 108 <= width <= 120 and 570 <= count <= 800:
        hint = "possible_core_panel_action"
    return {"hint": hint, "green_pixels": count, "glyph_band_width": width}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    site = args.site.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    source_sha = (site / "PLAYTEST_BUILD.txt").read_text().strip()
    if len(source_sha) != 40 or any(ch not in "0123456789abcdef" for ch in source_sha):
        raise RuntimeError("Missing exact-source build marker")
    browser_path = next((path for path in [shutil.which("google-chrome"), shutil.which("chromium"), shutil.which("chromium-browser")] if path), None)
    if not browser_path:
        raise RuntimeError("GitHub runner has no installed Chromium/Chrome executable")

    import os
    old_cwd = os.getcwd()
    os.chdir(site)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), IsolatedHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    url = "http://127.0.0.1:%d/index.html" % server.server_port

    evidence = {
        "source_sha": source_sha,
        "mode": "automated_blackbox_keyboard_in_real_chromium",
        "human_perceptual_listening": False,
        "audio_output_audibility": "UNVERIFIED",
        "browser_path": browser_path,
        "steps": [],
        "messages": [],
        "finished": False,
    }
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(
                executable_path=browser_path, headless=True,
                args=[
                    "--no-sandbox", "--disable-dev-shm-usage",
                    "--enable-webgl", "--enable-unsafe-swiftshader",
                    "--use-gl=angle", "--use-angle=swiftshader",
                    "--disable-gpu-sandbox", "--autoplay-policy=no-user-gesture-required",
                ],
            )
            context = browser.new_context(viewport={"width": 960, "height": 540})
            page = context.new_page()
            page.on("console", lambda message: evidence["messages"].append(
                {"type": "console_" + message.type, "text": message.text[:500]}))
            page.on("pageerror", lambda error: evidence["messages"].append(
                {"type": "page_error", "text": str(error)[:600]}))
            page.on("crash", lambda: evidence["messages"].append(
                {"type": "page_crash", "text": "browser page crashed"}))
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            evidence["cross_origin_isolated"] = page.evaluate("window.crossOriginIsolated")
            # The Godot bootstrap removes the progress/status element only after
            # WebAssembly and the large .pck finish loading and Engine.startGame() resolves.
            page.locator("#status").wait_for(state="detached", timeout=180000)
            canvas = page.locator("#canvas")
            canvas.wait_for(state="visible", timeout=12000)
            canvas.focus()
            page.wait_for_timeout(1700)
            first = output / "01_spawn.png"
            page.screenshot(path=str(first))
            evidence["steps"].append("load and screenshot game spawn")
            if page.evaluate("document.getElementById('canvas').width") < 200:
                raise RuntimeError("Godot canvas width too small")

            page.keyboard.down("w")
            page.wait_for_timeout(1500)
            page.keyboard.up("w")
            page.wait_for_timeout(550)
            second = output / "02_walk_forward.png"
            page.screenshot(path=str(second))
            evidence["steps"].append("hold W 1.5s, release, screenshot")

            page.keyboard.down("a")
            page.keyboard.down("w")
            page.wait_for_timeout(1100)
            page.keyboard.up("a")
            page.keyboard.up("w")
            page.wait_for_timeout(450)
            third = output / "03_diagonal_traverse.png"
            page.screenshot(path=str(third))
            evidence["steps"].append("hold W+A 1.1s, release, screenshot")

            page.keyboard.press("r")
            page.wait_for_timeout(700)
            fourth = output / "04_toggle_radio.png"
            page.screenshot(path=str(fourth))
            evidence["steps"].append("toggle R radio, screenshot")

            page.keyboard.press("m")
            page.wait_for_timeout(750)
            fifth = output / "05_map.png"
            page.screenshot(path=str(fifth))
            evidence["steps"].append("toggle M map, screenshot")

            page.keyboard.press("m")
            page.keyboard.press("e")
            page.wait_for_timeout(800)
            sixth = output / "06_action.png"
            page.screenshot(path=str(sixth))
            evidence["steps"].append("close map and attempt E action, screenshot")

            # Independent real-keyboard attempt toward the initial bike objective.
            # This is not an internal state setter and does not assert a mount.
            # Restart after the earlier diagnostic motions so the approach is reproducible.
            page.reload(wait_until="domcontentloaded", timeout=30000)
            page.locator("#status").wait_for(state="detached", timeout=180000)
            page.locator("#canvas").focus()
            page.wait_for_timeout(900)
            seventh = output / "07_fresh_bike_attempt.png"
            page.screenshot(path=str(seventh))
            evidence["steps"].append("reload for independent first-bike keyboard attempt")

            # Camera-relative W advances through the opening corridor; adding D
            # next follows the forward/right projection toward the parked bike.
            page.keyboard.down("w")
            page.wait_for_timeout(360)
            page.keyboard.down("d")
            page.wait_for_timeout(680)
            page.keyboard.up("d")
            page.keyboard.up("w")
            page.wait_for_timeout(350)
            eighth = output / "08_bike_approach.png"
            page.screenshot(path=str(eighth))
            evidence["steps"].append("real keyboard: W 0.36s, then W+D 0.68s, screenshot bike approach")

            # Avoid an early blind E: it previously mounted a different
            # vehicle when framerate-dependent travel landed beside a coupe.
            ninth = output / "09_bike_mount_attempt.png"
            page.screenshot(path=str(ninth))
            evidence["steps"].append("observe early approach; skip blind E before target identified")
            evidence["visual_action_hints"] = []
            evidence["visual_action_hints"].append(
                {"frame": ninth.name, **visually_inspect_action_label(ninth)}
            )

            page.keyboard.down("w")
            page.wait_for_timeout(900)
            page.keyboard.up("w")
            page.wait_for_timeout(500)
            tenth = output / "10_after_mount_attempt.png"
            page.screenshot(path=str(tenth))
            evidence["steps"].append("real W 0.9s, screenshot before selecting a vehicle")
            observation = visually_inspect_action_label(tenth)
            evidence["visual_action_hints"].append({"frame": tenth.name, **observation})
            candidate = observation["hint"] == "possible_courier_action"

            if not candidate:
                # Bounded real-keyboard corrective probes. In the observed
                # wrong-coupe frame, the game's existing live objective cue
                # points RIGHT. Probe short screen-right moves first rather
                # than blindly walking away to the left; check the actual
                # action glyph after every move and never press E on a coupe.
                # Motion remains framerate-dependent, so failure is reported.
                for index, (key, duration_ms) in enumerate([
                    ("d", 180), ("d", 180), ("d", 200), ("d", 200),
                    ("w", 180), ("d", 200), ("s", 220), ("a", 240),
                    ("a", 240), ("s", 200), ("d", 220), ("d", 220),
                ], 1):
                    page.keyboard.down(key)
                    page.wait_for_timeout(duration_ms)
                    page.keyboard.up(key)
                    page.wait_for_timeout(180)
                    probe = output / f"10b_search_{index:02d}.png"
                    page.screenshot(path=str(probe))
                    observation = visually_inspect_action_label(probe)
                    evidence["visual_action_hints"].append(
                        {"frame": probe.name, "keyboard": key, **observation}
                    )
                    if observation["hint"] == "possible_courier_action":
                        candidate = True
                        evidence["steps"].append(
                            f"visual courier prompt candidate appeared after real {key} navigation"
                        )
                        break

            evidence["courier_prompt_visual_candidate"] = candidate
            evidence["courier_candidate_is_authoritative"] = False
            if candidate:
                page.keyboard.press("e")
                page.wait_for_timeout(1100)
                evidence["steps"].append("press real E only on visually likely courier prompt")
            else:
                evidence["steps"].append(
                    "NO COURIER PROMPT: do not press E, avoid unintentionally mounting another vehicle"
                )

            eleventh = output / "11_bike_close_action.png"
            page.screenshot(path=str(eleventh))
            if candidate:
                page.keyboard.down("w")
                page.wait_for_timeout(1400)
                page.keyboard.up("w")
                page.wait_for_timeout(550)
                evidence["steps"].append("hold real W after candidate mount action")
            twelfth = output / "12_post_close_action_drive.png"
            page.screenshot(path=str(twelfth))

            evidence["bike_mount_verification"] = (
                "REQUIRES_VISUAL_INSPECTION_OF_11_AND_12"
                if candidate else "BLOCKED_NO_COURIER_PROMPT_CANDIDATE"
            )
            evidence["mission_outcome_verification"] = "UNVERIFIED"
            evidence["frame_change"] = {
                "spawn_to_forward": frame_change(first, second),
                "forward_to_diagonal": frame_change(second, third),
                "radio_to_map": frame_change(fourth, fifth),
                "fresh_start_to_bike_approach": frame_change(seventh, eighth),
                "approach_to_preaction": frame_change(eighth, ninth),
                "preaction_to_bike_candidate_search": frame_change(ninth, tenth),
                "candidate_action_to_followup": frame_change(eleventh, twelfth),
            }

            if candidate:
                # No state setters: real Space/E, on-foot movement and mouse.
                # This attempt is captured but must not be called a success
                # without inspection of the actual tuner and mission HUD.
                page.keyboard.down("Space")
                page.wait_for_timeout(1250)
                page.keyboard.up("Space")
                page.wait_for_timeout(350)
                thirteenth = output / "13_brake_for_tuner.png"
                page.screenshot(path=str(thirteenth))

                page.keyboard.press("e")
                page.wait_for_timeout(800)
                fourteenth = output / "14_tuner_dismount_attempt.png"
                page.screenshot(path=str(fourteenth))

                page.keyboard.down("w")
                page.keyboard.down("d")
                page.wait_for_timeout(540)
                page.keyboard.up("d")
                page.keyboard.up("w")
                page.wait_for_timeout(350)
                fourteenth_b = output / "14b_walk_to_tuner.png"
                page.screenshot(path=str(fourteenth_b))

                page.keyboard.press("e")
                page.wait_for_timeout(750)
                fifteenth = output / "15_tuner_interact_attempt.png"
                page.screenshot(path=str(fifteenth))

                page.mouse.move(300, 280)
                page.mouse.down()
                page.mouse.move(620, 280, steps=48)
                page.wait_for_timeout(850)
                sixteenth = output / "16_tuner_drag_held.png"
                page.screenshot(path=str(sixteenth))
                page.mouse.up()
                page.wait_for_timeout(600)
                seventeenth = output / "17_after_tuner_drag.png"
                page.screenshot(path=str(seventeenth))

                evidence["steps"].append(
                    "real Space/E, W+D and mouse-drag tuner attempt; outcome to inspect"
                )
                evidence["tuner_spoof_verification"] = "REQUIRES_VISUAL_INSPECTION_OF_13_TO_17"
                evidence["frame_change"].update({
                    "brake_to_dismount": frame_change(thirteenth, fourteenth),
                    "dismount_to_tuner_approach": frame_change(fourteenth, fourteenth_b),
                    "approach_to_tuner_interaction": frame_change(fourteenth_b, fifteenth),
                    "tuner_interaction_to_drag": frame_change(fifteenth, sixteenth),
                    "tuner_drag_to_release": frame_change(sixteenth, seventeenth),
                })

                # Follow the actual rendered [E] PEEL PANEL action, not a
                # presumed successful mission state. The game owns every
                # gesture, core extraction and pursuit transition.
                panel_hint = visually_inspect_action_label(seventeenth)
                evidence["visual_action_hints"].append({
                    "frame": seventeenth.name, **panel_hint
                })
                panel_candidate = panel_hint["hint"] == "possible_core_panel_action"
                evidence["panel_wayfinding_probes"] = []
                if not panel_candidate:
                    # After tuner lock the core is down-left in the verified
                    # rendered view. The former E prompt appeared outside the
                    # 2.5m action radius. Approach in small screen-relative
                    # steps, inspecting the actual [E] label after each.
                    # Never press E based solely on destination distance.
                    for index, (keys, duration_ms) in enumerate([
                        (("s", "a"), 200), (("s", "a"), 200),
                        (("s",), 170), (("a",), 170),
                        (("s",), 170), (("d",), 180),
                        (("w",), 170), (("d",), 170),
                        (("s",), 170), (("a",), 170),
                    ], 1):
                        for key in keys:
                            page.keyboard.down(key)
                        page.wait_for_timeout(duration_ms)
                        for key in reversed(keys):
                            page.keyboard.up(key)
                        page.wait_for_timeout(280)
                        approach = output / f"17b_panel_approach_{index:02d}.png"
                        page.screenshot(path=str(approach))
                        hint = visually_inspect_action_label(approach)
                        evidence["panel_wayfinding_probes"].append({
                            "frame": approach.name, "keyboard": "+".join(keys),
                            **hint
                        })
                        if hint["hint"] == "possible_core_panel_action":
                            panel_candidate = True
                            break
                evidence["core_panel_prompt_visual_candidate"] = panel_candidate
                evidence["core_panel_candidate_is_authoritative"] = False
                if panel_candidate:
                    page.keyboard.press("e")
                    page.wait_for_timeout(550)
                    eighteenth = output / "18_panel_peel_prompt_attempt.png"
                    page.screenshot(path=str(eighteenth))
                    evidence["steps"].append("press real E on visually likely [E] PEEL PANEL")

                    # The retained gesture requires a downward peel, not the
                    # horizontal tuner drag. A real mouse press, move, and
                    # release must produce the exposed-core UI on its own.
                    page.mouse.move(410, 190)
                    page.mouse.down()
                    page.mouse.move(410, 420, steps=42)
                    page.wait_for_timeout(450)
                    nineteenth = output / "19_panel_peel_drag_held.png"
                    page.screenshot(path=str(nineteenth))
                    page.mouse.up()
                    page.wait_for_timeout(300)
                    nineteenth_b = output / "19b_panel_peel_released.png"
                    page.screenshot(path=str(nineteenth_b))
                    evidence["steps"].append("real left-mouse drag downward 230px and release; screenshot exposure")

                    # [E] is the documented core-tap binding while the
                    # EXPOSE_CORE overlay is visible. Capture the result
                    # without calling any Godot state getter or setter.
                    page.keyboard.press("e")
                    page.wait_for_timeout(1000)
                    twentieth = output / "20_core_extraction_attempt.png"
                    page.screenshot(path=str(twentieth))
                    page.wait_for_timeout(5200)
                    twenty_first = output / "21_pursuit_after_core_attempt.png"
                    page.screenshot(path=str(twenty_first))
                    evidence["steps"].append("press real E to tap exposed core; observe 5.2 seconds for echo/pursuit")
                    evidence["core_extraction_verification"] = "REQUIRES_VISUAL_AND_CONSOLE_INSPECTION_OF_18_TO_21"
                    evidence["pursuit_verification"] = "REQUIRES_VISUAL_AND_CONSOLE_INSPECTION_OF_20_TO_21"
                    evidence["frame_change"].update({
                        "panel_prompt_to_peel_start": frame_change(seventeenth, eighteenth),
                        "peel_start_to_drag": frame_change(eighteenth, nineteenth),
                        "peel_release_to_core_attempt": frame_change(nineteenth_b, twentieth),
                        "core_attempt_to_pursuit_observation": frame_change(twentieth, twenty_first),
                    })
                else:
                    evidence["core_extraction_verification"] = "NOT_ATTEMPTED_NO_PANEL_ACTION_CANDIDATE"
                    evidence["pursuit_verification"] = "NOT_ATTEMPTED_NO_PANEL_ACTION_CANDIDATE"
            else:
                evidence["tuner_spoof_verification"] = "NOT_ATTEMPTED_NO_COURIER_CANDIDATE"
                evidence["core_extraction_verification"] = "NOT_ATTEMPTED_NO_COURIER_CANDIDATE"
                evidence["pursuit_verification"] = "NOT_ATTEMPTED_NO_COURIER_CANDIDATE"

            evidence["canvas"] = page.evaluate("({w:canvas.width,h:canvas.height})")
            evidence["finished"] = True
            context.close()
            browser.close()
    except Exception as exc:
        evidence["failure"] = str(exc)
    finally:
        server.shutdown()
        os.chdir(old_cwd)
        (output / "playthrough.json").write_text(json.dumps(evidence, indent=2) + "\n")
        print(json.dumps({
            "finished": evidence["finished"], "source_sha": source_sha,
            "frame_change": evidence.get("frame_change", {}),
            "failure": evidence.get("failure"),
            "messages_tail": evidence["messages"][-8:],
        }), flush=True)
    return 0 if evidence["finished"] else 2


if __name__ == "__main__":
    raise SystemExit(main())

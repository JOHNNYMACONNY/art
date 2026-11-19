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

            page.keyboard.press("e")
            page.wait_for_timeout(1000)
            ninth = output / "09_bike_mount_attempt.png"
            page.screenshot(path=str(ninth))
            evidence["steps"].append("press E near expected bike, screenshot; mount not automatically asserted")

            page.keyboard.down("w")
            page.wait_for_timeout(900)
            page.keyboard.up("w")
            page.wait_for_timeout(500)
            tenth = output / "10_after_mount_attempt.png"
            page.screenshot(path=str(tenth))
            evidence["steps"].append("real W after mount attempt, screenshot; inspect action eligibility")

            # A second, intentional real keypress occurs after walking close
            # to the bike. The prior E press was too early in captured footage.
            page.keyboard.press("e")
            page.wait_for_timeout(1100)
            eleventh = output / "11_bike_close_action.png"
            page.screenshot(path=str(eleventh))
            evidence["steps"].append("press real E at close bike after 0.9s W, screenshot mission transition")

            page.keyboard.down("w")
            page.wait_for_timeout(1400)
            page.keyboard.up("w")
            page.wait_for_timeout(550)
            twelfth = output / "12_post_close_action_drive.png"
            page.screenshot(path=str(twelfth))
            evidence["steps"].append("hold real W after close-range E, screenshot potential vehicle travel")
            evidence["bike_mount_verification"] = "REQUIRES_VISUAL_INSPECTION_OF_11_AND_12"
            evidence["mission_outcome_verification"] = "UNVERIFIED"

            # Issue #214: after the optional real courier ride, the next
            # experience is to stop, dismount, use E on the mast, and tune by
            # dragging the on-screen dial. These are genuine browser inputs.
            # We record what happens, not assert success from elapsed time.
            page.keyboard.down("Space")
            page.wait_for_timeout(1250)
            page.keyboard.up("Space")
            page.wait_for_timeout(350)
            thirteenth = output / "13_brake_for_tuner.png"
            page.screenshot(path=str(thirteenth))
            evidence["steps"].append("real Space handbrake/coast, screenshot before tuner dismount")

            page.keyboard.press("e")
            page.wait_for_timeout(800)
            fourteenth = output / "14_tuner_dismount_attempt.png"
            page.screenshot(path=str(fourteenth))
            evidence["steps"].append("real E dismount attempt at tuner, screenshot; outcome to inspect")

            # The tuner is a separate world-space object; dismounting beside
            # the bike does not itself put the player within its 2.5m action
            # radius. Walk the last meters (screen-relative north) before E.
            page.keyboard.down("w")
            page.keyboard.down("d")
            page.wait_for_timeout(540)
            page.keyboard.up("d")
            page.keyboard.up("w")
            page.wait_for_timeout(350)
            fourteenth_b = output / "14b_walk_to_tuner.png"
            page.screenshot(path=str(fourteenth_b))
            evidence["steps"].append("real W+D on-foot approach from parked bike to tuner marker")

            page.keyboard.press("e")
            page.wait_for_timeout(750)
            fifteenth = output / "15_tuner_interact_attempt.png"
            page.screenshot(path=str(fifteenth))
            evidence["steps"].append("real E tuner interaction attempt, screenshot; overlay to inspect")

            # The tuner uses a cumulative horizontal pointer delta, saturating
            # by tanh. A ~320px positive sweep targets 0.72 from its default
            # 0.15 frequency; hold in tolerance for its 0.4s dwell requirement.
            # Do not synthesize gameplay/mission state or call Godot internals.
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
            evidence["steps"].append("real left-mouse 320px horizontal tuner drag with hold, before/after screenshots")
            evidence["tuner_spoof_verification"] = "REQUIRES_VISUAL_INSPECTION_OF_13_TO_17"

            evidence["frame_change"] = {
                "spawn_to_forward": frame_change(first, second),
                "forward_to_diagonal": frame_change(second, third),
                "radio_to_map": frame_change(fourth, fifth),
                "fresh_start_to_bike_approach": frame_change(seventh, eighth),
                "approach_to_mount_attempt": frame_change(eighth, ninth),
                "mount_attempt_to_movement": frame_change(ninth, tenth),
                "close_action_to_drive": frame_change(eleventh, twelfth),
                "brake_to_dismount": frame_change(thirteenth, fourteenth),
                "dismount_to_tuner_approach": frame_change(fourteenth, fourteenth_b),
                "approach_to_tuner_interaction": frame_change(fourteenth_b, fifteenth),
                "tuner_interaction_to_drag": frame_change(fifteenth, sixteenth),
                "tuner_drag_to_release": frame_change(sixteenth, seventeenth),
            }
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

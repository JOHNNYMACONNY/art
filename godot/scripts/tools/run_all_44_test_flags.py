import subprocess
import sys
import time

FLAGS = [
    "--run-v1-assertions",
    "--run-v2-assertions",
    "--run-v3-assertions",
    "--run-v4-assertions",
    "--run-v5-assertions",
    "--run-v6-assertions",
    "--run-v7-ticket01-assertions",
    "--run-v7-ticket02-1-assertions",
    "--run-v7-ticket02-assertions",
    "--run-v7-ticket03-assertions",
    "--run-v7-ticket03-stress-retest",
    "--run-v7-ticket04-1-assertions",
    "--run-v7-ticket04-2-assertions",
    "--run-v7-ticket04-3-assertions",
    "--run-v7-ticket05-assertions",
    "--run-v7-ticket06-1-assertions",
    "--run-v7-ticket06-2-assertions",
    "--run-v7-ticket06-3-assertions",
    "--run-v7-ticket06-assertions",
    "--run-v8-assertions",
    "--run-v8-m03-aftermath-assertions",
    "--run-v8-m04-echo-assertions",
    "--run-v8-m05-hero-identity-assertions",
    "--run-v8-m06-vehicle-class-assertions",
    "--run-v8-m07-world-life-assertions",
    "--run-v8-m15-assertions",
    "--run-v8-m15-fast-retry-assertions",
    "--run-v8-m21-assertions",
    "--run-v8-m21-audio-registry-assertions",
    "--run-v8-m22-assertions",
    "--run-v8-m22-radio-director-assertions",
    "--run-v8-m22-radio-program-assertions",
    "--run-v8-m23-assertions",
    "--run-v8-m23-radio-assertions",
    "--run-v8-m23-vehicle-radio-assertions",
    "--run-v8-m24-assertions",
    "--run-v8-m24-radio-mix-assertions",
    "--run-v8-m25-assertions",
    "--run-v8-m25-echo-radio-interference-assertions",
    "--run-v8-multitouch-assertions",
    "--run-v8-readability",
    "--run-v8-safe-area-assertions",
    "--run-v8-telemetry",
    "--run-v8-thumb-reach-assertions",
]

passed = []
failed = []

start_total = time.time()
print(f"Starting execution of all {len(FLAGS)} CLI test flags in Godot headless...")

for idx, flag in enumerate(FLAGS, 1):
    cmd = [
        "godot",
        "--headless",
        "--path",
        "godot",
        "res://scenes/prototype/scrap_test_block.tscn",
        "--",
        flag
    ]
    t0 = time.time()
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    dur = time.time() - t0
    
    if res.returncode == 0:
        print(f"[{idx:2d}/{len(FLAGS)}] PASS: {flag} ({dur:.2f}s)")
        passed.append(flag)
    else:
        print(f"[{idx:2d}/{len(FLAGS)}] FAIL (code {res.returncode}): {flag}")
        print("--- STDOUT ---")
        print(res.stdout[-400:] if len(res.stdout) > 400 else res.stdout)
        print("--- STDERR ---")
        print(res.stderr[-400:] if len(res.stderr) > 400 else res.stderr)
        failed.append(flag)

total_dur = time.time() - start_total
print(f"\n==========================================")
print(f"TOTAL: {len(FLAGS)} | PASSED: {len(passed)} | FAILED: {len(failed)} in {total_dur:.1f}s")
print(f"==========================================")

if len(failed) > 0:
    sys.exit(1)
else:
    print("ALL 44 CLI TEST FLAGS VERIFIED 100% PASSING!")
    sys.exit(0)

# /// script
# requires-python = ">=3.11"
# dependencies = ["miniaudio==1.71"]
# ///

import argparse
import signal
import sys
import time
from collections.abc import Sequence
from typing import Any

import miniaudio

SAMPLE_RATE = 48_000
PLAYBACK_CHANNELS = 2


def parse_channels(value: str) -> tuple[int, int]:
    parts = value.split(",")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError("expected L,R, for example 3,4")

    try:
        left, right = (int(part) for part in parts)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("channels must be integers") from exc

    if left < 1 or right < 1:
        raise argparse.ArgumentTypeError("channels are 1-based and must be positive")

    return left, right


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dsp",
        description="Monitor Nano Cortex processed USB audio through EarPods.",
    )
    parser.add_argument("--input", default="Nano Cortex", help="capture device name")
    parser.add_argument("--output", default="EarPods", help="playback device name")
    parser.add_argument(
        "--channels",
        type=parse_channels,
        default=(3, 4),
        help="1-based input channels to monitor, default: 3,4",
    )
    parser.add_argument("--buffer-ms", type=int, default=5, help="buffer size in ms")
    parser.add_argument("--gain", type=float, default=2.0, help="linear gain")
    parser.add_argument("--limit", type=float, default=0.95, help="peak limiter threshold")
    parser.add_argument("--list-devices", action="store_true", help="list devices and exit")
    return parser


def find_device(devices: Sequence[dict[str, Any]], name: str, kind: str) -> dict[str, Any]:
    for device in devices:
        if device["name"] == name:
            return device

    print(f"dsp: {kind} device not found: {name}", file=sys.stderr)
    print(f"available {kind} devices:", file=sys.stderr)
    for device in devices:
        print(f"  - {device['name']}", file=sys.stderr)
    raise SystemExit(1)


def channel_count(device: dict[str, Any]) -> int:
    return max((fmt.get("channels", 0) for fmt in device.get("formats", ())), default=0)


def print_devices(playbacks: Sequence[dict[str, Any]], captures: Sequence[dict[str, Any]]) -> None:
    print("Playback devices:")
    for device in playbacks:
        print(f"  - {device['name']}")
        for fmt in device.get("formats", ()):
            print(
                f"      {fmt.get('samplerate')} Hz, "
                f"{fmt.get('channels')} ch, {fmt.get('format')}"
            )

    print("Capture devices:")
    for device in captures:
        print(f"  - {device['name']}")
        for fmt in device.get("formats", ()):
            print(
                f"      {fmt.get('samplerate')} Hz, "
                f"{fmt.get('channels')} ch, {fmt.get('format')}"
            )


def make_bridge(
    *,
    capture_channels: int,
    left_index: int,
    right_index: int,
    gain: float,
    limit: float,
):
    in_bytes = yield b""
    lower_limit = -limit

    while True:
        samples = memoryview(in_bytes).cast("f")
        frames = len(samples) // capture_channels
        out_bytes = bytearray(frames * PLAYBACK_CHANNELS * 4)
        out = memoryview(out_bytes).cast("f")

        out_index = 0
        for frame_index in range(frames):
            base = frame_index * capture_channels
            left = samples[base + left_index] * gain
            right = samples[base + right_index] * gain

            if left > limit:
                left = limit
            elif left < lower_limit:
                left = lower_limit

            if right > limit:
                right = limit
            elif right < lower_limit:
                right = lower_limit

            out[out_index] = left
            out[out_index + 1] = right
            out_index += PLAYBACK_CHANNELS

        in_bytes = yield out


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.buffer_ms < 1:
        parser.error("--buffer-ms must be >= 1")
    if args.limit <= 0:
        parser.error("--limit must be > 0")

    devices = miniaudio.Devices()
    playbacks = devices.get_playbacks()
    captures = devices.get_captures()

    if args.list_devices:
        print_devices(playbacks, captures)
        return 0

    playback = find_device(playbacks, args.output, "playback")
    capture = find_device(captures, args.input, "capture")
    capture_channels = channel_count(capture)
    if capture_channels < 1:
        print(f"dsp: capture device reports no input channels: {args.input}", file=sys.stderr)
        return 1

    left_channel, right_channel = args.channels
    if left_channel > capture_channels or right_channel > capture_channels:
        print(
            f"dsp: requested channels {left_channel},{right_channel}, "
            f"but {args.input} reports {capture_channels} input channels",
            file=sys.stderr,
        )
        return 1

    running = True

    def stop(_signum, _frame):
        nonlocal running
        running = False

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    callback = make_bridge(
        capture_channels=capture_channels,
        left_index=left_channel - 1,
        right_index=right_channel - 1,
        gain=args.gain,
        limit=args.limit,
    )
    next(callback)

    stream = miniaudio.DuplexStream(
        playback_format=miniaudio.SampleFormat.FLOAT32,
        playback_channels=PLAYBACK_CHANNELS,
        capture_format=miniaudio.SampleFormat.FLOAT32,
        capture_channels=capture_channels,
        sample_rate=SAMPLE_RATE,
        buffersize_msec=args.buffer_ms,
        playback_device_id=playback["id"],
        capture_device_id=capture["id"],
        callback_periods=1,
        app_name="dsp",
    )

    stream.start(callback)
    print(
        f"dsp: {args.input} ch {left_channel}/{right_channel} -> {args.output}, "
        f"buffer {args.buffer_ms} ms, gain {args.gain}, limit {args.limit}"
    )
    print(f"dsp: backend {stream.backend}; press Ctrl-C to stop")
    sys.stdout.flush()

    try:
        while running:
            time.sleep(0.2)
    finally:
        stream.close()

    print("dsp: stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

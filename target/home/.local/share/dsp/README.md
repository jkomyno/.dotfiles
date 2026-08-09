# dsp

`dsp` monitors a Neural DSP Nano Cortex through USB and plays the processed
stereo guitar signal through USB-C EarPods on macOS.

This exists for the case where the Nano Cortex is connected to the Mac as an
audio interface, but the headphones cannot be plugged directly into the Nano
because they are USB-C rather than analog mini-jack.

## Signal route

Default route:

```text
Guitar -> Nano Cortex -> USB input channels 3/4 -> Mac -> EarPods
```

Nano Cortex exposes an 8-channel USB input device to macOS. In this setup,
channels 3/4 carried the processed stereo signal. Channel 1 carried a dry DI
signal during testing, so it is not the default monitoring source.

## How it runs

`~/.local/bin/dsp` is a small shell launcher. It runs this Python script through
`uv`:

```sh
uv run --no-project --script ~/.local/share/dsp/monitor.py
```

The Python script uses `miniaudio` over CoreAudio to open:

- capture device: `Nano Cortex`
- playback device: `EarPods`
- sample rate: `48000`
- default buffer: `5 ms`

The script has inline PEP 723 metadata, so `uv` resolves `miniaudio` without a
manually managed virtualenv.

## Usage

```sh
dsp
dsp --buffer-ms 3
dsp --channels 1,1
dsp --list-devices
```

Press `Ctrl-C` to stop the monitor.

## Latency

This is a software monitor. It round-trips audio through the Mac:

```text
Nano USB input -> CoreAudio capture -> Python channel copy -> CoreAudio output -> EarPods
```

The remaining delay cannot be fully removed in software. The lowest-latency
monitoring option is still direct analog monitoring from the Nano Cortex output.

Practical buffer settings:

- `5 ms`: current default, stable during testing.
- `3 ms`: lower latency, may crackle.
- `2 ms`: lowest practical setting to try, more likely to drop out.

## Implementation notes

The audio callback is intentionally simple:

- read float32 frames from the 8-channel capture buffer;
- copy selected input channels into a stereo float32 output buffer;
- apply linear gain;
- clamp peaks to the configured limit.

Avoid adding logging, allocation-heavy work, subprocess calls, or device
enumeration inside the callback. Those belong before the stream starts.

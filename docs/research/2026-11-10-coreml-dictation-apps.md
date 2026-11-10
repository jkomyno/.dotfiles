# Core ML dictation apps and Unified integration

Research snapshot: 2026-11-10. Target: Apple M1 Pro, 32 GiB RAM, macOS 14.4.1, Swift 5.9. The survey below checks documentation and source. The local verification section records subsequent downloads and CLI/native inference probes by the parent agent. No microphone or text-insertion test was performed; no alternative GUI app was installed.

Follow-up: the [failure investigation](2026-11-10-coreml-failure-investigation.md) confirmed the saved errors but could not reproduce them in 15 subsequent full transcriptions and 32 encoder predictions. No prediction fix has been verified; the historical results below are preserved.

## Recommendation

**MacParakeet 0.8.10 is the strongest ready-made candidate by source compatibility for this machine and exact model, but the local repeat failure below prevents recommending a switch yet.** It is free, GPL-3.0, supports Apple Silicon on macOS 14.2+, and the released source routes its selectable English Unified model through FluidAudio's dedicated Core ML streaming manager. This is more specific than an app merely advertising Parakeet or Core ML. The release has a `MacParakeet.dmg` asset; the separate CLI 5.1.0 release has an approximately 20.7 MB arm64 tarball. [App release](https://github.com/moona3k/macparakeet/releases/tag/v0.8.10), [license](https://github.com/moona3k/macparakeet/blob/v0.8.10/LICENSE), [released engine](https://github.com/moona3k/macparakeet/blob/v0.8.10/Sources/MacParakeetCore/STT/ParakeetUnifiedEngine.swift), [CLI release](https://github.com/moona3k/macparakeet/releases/tag/cli-v5.1.0)

**TypeWhisper is the best verified extensibility option:** it runs on macOS 14+, has a free GPLv3 core and downloadable binaries, and exposes an SDK for custom transcription-engine plugins. However, its existing Parakeet import is specifically a TDT pipeline; importing Unified's RNNT bundles into that plugin is not a supported shortcut. A new Unified plugin or a local HTTP bridge would be required. [Project](https://github.com/TypeWhisper/typewhisper-mac), [free core and requirements](https://www.typewhisper.com/en/), [import implementation](https://github.com/TypeWhisper/typewhisper-mac/blob/main/TypeWhisperPluginSDK/Plugins/ParakeetPlugin/ParakeetModelImport.swift)

## Verified comparison

| App | Free/open source status | Relevant engine support | Fit for macOS 14.4.1 |
| --- | --- | --- | --- |
| **MacParakeet 0.8.10** | Free binary and GPL-3.0 source | Explicit FluidAudio Unified Core ML INT8, plus selectable TDT/Nemotron/Cohere/WhisperKit engines. Curated integrations rather than an arbitrary Core ML importer. | **Yes by published requirements: macOS 14.2+, M-series.** Local CLI repeat failures are recorded below. |
| **TypeWhisper 1.8.2** | Free core, GPLv3; optional paid Premium | Engine plugins, Core ML through FluidAudio/WhisperKit, compatible custom TDT imports, OpenAI-compatible HTTP transcription. No existing Unified manager integration found in the Parakeet plugin. | **Yes: app and Parakeet plugin declare macOS 14.** New Unified integration needed. |
| **FluidVoice 1.6.12** | Free GPLv3 app; optional Fluid Intelligence cleanup weights are private | Core ML engines are integrated per architecture. Current catalog lists TDT v2/v3, EOU/Flash, Nemotron and others. An `ExternalCoreMLModelRegistry` name does not mean generic import: its backend enum currently names Cohere. Exact Unified support was not established. | **No: macOS 15+**. |
| **VoiceInk 2.26** | GPLv3 source and documented free local build; official packaged app is a trial/purchase product | Explicit `UnifiedAsrManager` and `StreamingUnifiedAsrManager`, with INT8 selected. | **No: macOS 15+, Swift 6.2+ for builds.** |
| **Hex 3.3.0 (anomalyco)** | Free downloads, MIT | Current Unified artifact is Handy's Q8 GGUF, not FluidInference's Core ML bundle. Older `kitlangton/Hex` used FluidAudio TDT v3; those are different implementations. | **No: current Mac app requires macOS 15+.** |
| **Dictate Anywhere** | MIT, downloadable Mac app | FluidAudio models including TDT v3/Ultra, SenseVoice and Nemotron; no Unified integration was found. No arbitrary Core ML importer verified. | **Yes by published requirements: macOS 14+.** Does not establish support for the requested model. |

Sources for the table: [MacParakeet released specification](https://github.com/moona3k/macparakeet/blob/v0.8.10/spec/06-stt-engine.md), [TypeWhisper plugin manifest](https://github.com/TypeWhisper/typewhisper-mac/blob/main/TypeWhisperPluginSDK/Plugins/ParakeetPlugin/manifest.json), [FluidVoice README](https://github.com/altic-dev/FluidVoice/blob/main/README.md), [FluidVoice external registry](https://github.com/altic-dev/FluidVoice/blob/main/Sources/Fluid/Services/ExternalCoreMLModelRegistry.swift), [VoiceInk runtime](https://github.com/Beingpax/VoiceInk/blob/main/VoiceInk/Infrastructure/Providers/Transcription/FluidAudio/FluidAudioTranscriptionService.swift), [VoiceInk build requirements](https://github.com/Beingpax/VoiceInk/blob/main/BUILDING.md), [Hex artifacts](https://github.com/anomalyco/hex/blob/dev/src/transcription/artifacts.rs), [Hex requirements](https://github.com/anomalyco/hex/blob/dev/docs/test-builds.md), [Dictate Anywhere](https://github.com/hoomanaskari/mac-dictate-anywhere).

## How MacParakeet can reuse the downloaded model

The released `ParakeetUnifiedEngine` selects INT8 and the default `70_13_13` streaming export (2.08 seconds algorithmic context delay). It uses streaming for file transcription and final dictation too, to obtain token timings. Its required files are:

```text
parakeet_unified_encoder_streaming_70_13_13_int8.mlmodelc/
parakeet_unified_decoder.mlmodelc/
parakeet_unified_joint_decision_single_step.mlmodelc/
vocab.json
metadata.json
```

An offline encoder alone is insufficient for this app path. The preprocessor bundle is unnecessary in the pinned FluidAudio version, which computes mel features in Swift. The release pins FluidAudio 0.17.7, revision `503b4bd1bbf7220882de39fe8ae6716aae4132da`. [Released engine](https://github.com/moona3k/macparakeet/blob/v0.8.10/Sources/MacParakeetCore/STT/ParakeetUnifiedEngine.swift), [pinned dependencies](https://github.com/moona3k/macparakeet/blob/v0.8.10/Package.resolved), [pinned model registry](https://github.com/FluidInference/FluidAudio/blob/503b4bd1bbf7220882de39fe8ae6716aae4132da/Sources/FluidAudio/ModelNames.swift)

There is no model-directory option in the inspected transcription command. The production cache resolves through FluidAudio to `~/Library/Application Support/FluidAudio/Models/parakeet-unified-en-0.6b`. A reusable snapshot containing the required files could be linked there, avoiding a second weight copy. For an isolated smoke run, the released code accepts the environment override `MACPARAKEET_DEBUG_APP_STATE_DIR` without a Debug-build restriction. This changes the expected model directory to `<state>/FluidAudio/Models/parakeet-unified-en-0.6b`. The local probe linked that directory to the canonical model snapshot and successfully transcribed once; subsequent prediction failures are recorded below. [Path resolver](https://github.com/moona3k/macparakeet/blob/v0.8.10/Sources/MacParakeetCore/Services/AppPaths.swift)

The released CLI supports the following bounded invocation, with telemetry disabled for the probe, explicit raw processing and no speaker model or saved history:

```sh
DO_NOT_TRACK=1 \
MACPARAKEET_DEBUG_APP_STATE_DIR=/absolute/test-state \
macparakeet-cli transcribe /absolute/sample.wav \
  --engine parakeet --parakeet-model unified \
  --mode raw --speaker-detection off --no-history --format json
```

`--no-history` still initializes an app database, so the state-directory override matters. This invocation does not select Unified as a saved default. [Released transcription command](https://github.com/moona3k/macparakeet/blob/v0.8.10/Sources/CLI/Commands/TranscribeCommand.swift)

## Custom engines and bridges

Core ML defines model execution and serialization; an app still needs architecture-specific audio preprocessing, decoder logic and vocabulary handling. Thus, a custom TDT importer cannot automatically run the Unified RNNT pipeline.

TypeWhisper's existing OpenAI Compatible plugin sends multipart batch requests to `/v1/audio/transcriptions` and permits an explicit WAV upload mode. A localhost server wrapping FluidAudio Unified could therefore be used as its engine without changing TypeWhisper's native runtime. This is an implementation route supported by the client's protocol, not a bridge already built or tested in this research. [HTTP plugin contract](https://github.com/TypeWhisper/typewhisper-mac/blob/main/TypeWhisperPluginSDK/Plugins/OpenAICompatiblePlugin/README.md)

Separately, Glimpse publishes a **different** Unified Core ML encoder derived from Handy's GGUF and intended for a transcribe.cpp Core ML adapter. It runs alongside the full GGUF; it is not interchangeable with FluidInference's multi-stage bundle. The claimed M2 Pro benefit applies to its offline encoder only, while live streaming remains on the GGUF GPU path. Whether Handy's pinned engine exposes that adapter is a separate source/runtime check. [Glimpse encoder and integration contract](https://huggingface.co/Glimpse-Dictation/Parakeet-Unified-EN-0.6B-coreml)

## Local verification performed

### Downloads and storage

Downloaded both variants into the shared Hugging Face hub cache, without changing Handy's selected model:

| Variant | Pinned revision | Downloaded files |
| --- | --- | ---: |
| Handy Unified Q8_0 GGUF | `7e948f21b7bdbac698d3318db9d350f1096f3b6c` from Handy's released catalog | 731,357,568 bytes |
| FluidInference Unified Core ML INT8 | `d32e972dd4315f1dc3f6be28fb2aab0ab3e80358` | 1,209,685,258 bytes |

The Core ML download includes offline and default streaming INT8 encoders, shared decoder/joint stages, and metadata. Other FP16 encoders and streaming tiers were omitted. Total downloaded model artifacts: **1,941,042,826 bytes, about 1.81 GiB**, plus runtime/compiler caches. Large-file SHA-256 values were verified against the Hugging Face API; file sizes were also checked. The CLI archive was checked against its published SHA-256 and the extracted binary passed strict code-signature verification. [GGUF repository](https://huggingface.co/handy-computer/parakeet-unified-en-0.6b-gguf), [FluidInference repository](https://huggingface.co/FluidInference/parakeet-unified-en-0.6b-coreml)

Handy's `--list-models --json` reports the GGUF as downloaded, with its catalog name and streaming capability. It resolves the shared cache without an extra model copy. The isolated MacParakeet model directory links to the same Core ML snapshot; it does not duplicate the weights.

### Actual runtime checks

The input was one 4.128-second local synthetic English recording: “Please inspect the Rust build cache and explain why this project uses so much disk space.” It is a smoke sample, not an accuracy benchmark or a substitute for real accented/noisy dictation.

- **Handy 0.10.0, GGUF, M1 Pro Metal:** successful three-repeat run; model load 406 ms, transcription 683 / 154 / 125 ms. A later fresh-process run also succeeded, with 1,869 ms load and 2,862 ms transcription during substantial machine load. These variable figures do not establish stable latency. Initial Metal shader compilation took 27.2 seconds before the first model-list operation completed.
- **Native Core ML, offline INT8 encoder:** the encoder, decoder and single-step joint model loaded with `.cpuAndNeuralEngine` permitted. Initial encoder load took 41.9 seconds. A later native probe completed three synchronous encoder predictions on a fixed zero-valued 15-second mel input (2.36 / 0.61 / 0.55 seconds). This validates model execution, not speech recognition, exclusive ANE execution, or full-pipeline latency.
- **MacParakeet CLI 5.1.0, FluidAudio Unified streaming INT8:** the first full transcription succeeded and returned the same text as Handy, including capitalization of “Rust Build.” Two subsequent fresh-process attempts on the same audio and cached model failed during prediction with `Unable to compute the asynchronous prediction using ML Program. It can be an invalid input data or broken/unsupported model.` The system log reports E5RT error 10 with private details. The exact fault is unproven; the observation does not establish whether it is in the app, streaming export, Core ML caching or this OS version.

The latter failure blocks a reliable app-level comparison. The earlier native offline success does not clear the separate streaming path. **Keep Handy/GGUF for routine use for now; treat MacParakeet/Core ML as a working first-run proof with an unresolved repeat failure.** No microphone or text insertion was tested. Handy's selected model, paste method and automatic-submission setting were verified unchanged after the probes. MacParakeet used isolated state, raw transcription, no speaker detection, no saved history and telemetry opt-out.

Private manifests, probe sources, commands and raw results are retained under `~/.local/state/dotfiles/voice-engine-2026-11-10/`; model artifacts remain under `~/.cache/huggingface/hub/`.

## What using FluidInference with Handy would require

Stock Handy 0.10.0 discovers `.bin`/`.gguf` model files and runs its transcription worker through transcribe.cpp. Its release has no FluidAudio/Core ML engine selection or configurable external transcription-server endpoint. Its custom model discovery skips model directories and other extensions, so copying or renaming FluidInference's bundles cannot add that runtime. [Released discovery](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/src/managers/model.rs#L1509), [worker](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/src/engine_supervisor/worker.rs), [dependencies](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/Cargo.toml)

A Handy fork could retain the recording/hotkey/paste UI while adding a FluidAudio adapter to the transcription worker, architecture-aware model discovery, and native Swift/Rust packaging. A localhost FluidAudio service would still require adding an external STT client to Handy. Neither is a settings-only solution; neither was implemented in this investigation. FluidAudio's current package requires Swift 6, newer than the installed Swift 5.9, although the prebuilt MacParakeet CLI runs here. [FluidAudio package requirements](https://github.com/FluidInference/FluidAudio/blob/main/Package.swift)

**Glimpse provides a separate route to Core ML**, rather than reuse of FluidInference's pipeline. It is AGPL-3.0 and declares macOS 14.0 minimum. Its speech package uses a fork of transcribe.cpp with the `coreml` feature enabled; Handy's pinned upstream transcribe.cpp 0.4.0 has no such feature or adapter. Glimpse's separate FP16 Core ML encoder accompanies the same full GGUF, accelerates offline encoding, and leaves streaming on the GGUF encoder. The FluidInference bundles are not interchangeable with that companion. No Glimpse app/model was downloaded or tested here. [Glimpse license](https://github.com/glimpse-hq/Glimpse/blob/main/LICENSE), [OS declaration](https://github.com/glimpse-hq/Glimpse/blob/main/src-tauri/tauri.conf.json), [fork dependency and feature](https://github.com/glimpse-hq/Glimpse-Speech/blob/3.0.4/Cargo.toml), [companion contract](https://huggingface.co/Glimpse-Dictation/Parakeet-Unified-EN-0.6B-coreml)

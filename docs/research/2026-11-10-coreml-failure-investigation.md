# Unified Core ML failure investigation

Date: 2026-11-10. Machine: Apple M1 Pro, 32 GiB, macOS 14.4.1. Status: **historical failures confirmed; not reproduced in this investigation; no prediction fix claimed or applied.**

## Affected component

The failing command uses MacParakeet CLI 5.1.0 and FluidAudio 0.17.7's Unified streaming INT8 model. Handy 0.10.0 runs its separate GGUF through transcribe.cpp; it does not have a FluidAudio/Core ML backend. The original two errors therefore cannot be attributed to a Handy Core ML implementation. [MacParakeet's released engine](https://github.com/moona3k/macparakeet/blob/v0.8.10/Sources/MacParakeetCore/STT/ParakeetUnifiedEngine.swift), [Handy's worker](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/src/engine_supervisor/worker.rs)

No repository WIP enters the standalone downloaded CLI's executable/model path, so stashing dotfiles would not isolate this failure. No app, model selection, model contents, system configuration, or global Core ML cache was changed during this investigation.

## Confirmed original failure

The earlier saved results contain one successful 4.128-second transcription followed by two fresh-process failures on the identical recording and model snapshot. The failures return:

```text
Transcription failed: Unable to compute the asynchronous prediction using ML Program.
It can be an invalid input data or broken/unsupported model.
```

The corresponding system log reports E5RT error 10, but hides the underlying message as private. Those errors are real. They establish neither invalid input nor a damaged model; the outer message lists possibilities rather than diagnosing one.

## Current reproduction results

| Check | Result |
| --- | --- |
| Initial rerun of the original short-audio command | 1/1 passed |
| Isolated fresh-process short transcriptions | 8/8 passed, 2.50–2.72 seconds per whole CLI run |
| Original Handy → MacParakeet interleaving | 2/2 Core ML runs passed |
| Short transcription with ten bounded CPU workers | 3/3 passed, 3.24–3.35 seconds per whole CLI run |
| Longer 49.536-second recording | 1/1 passed, all 192 expected words returned |
| Direct asynchronous streaming encoder, synthetic features | 8/8 predictions passed |
| New probe executable identity under bounded CPU load | 8/8 asynchronous predictions passed; model load 33.8 seconds |
| Direct streaming encoder with upstream mel extraction from the real short recording | 8/8 asynchronous and 8/8 synchronous predictions passed |

Totals: **15 successful full transcriptions and 32 successful low-level encoder predictions, with no current failure.** All supplied real-audio mel features were finite, with expected `[1,128,769]` shape and contiguous strides. The real-audio probe used the same pinned upstream `AudioMelSpectrogram` and `UnifiedMelExtractor` implementations as the CLI, compiled with the local Swift 5.9 toolchain. Short full transcriptions returned the same words as the original successful run.

Every downloaded large-file SHA-256 was rechecked against the original download manifest and still matches. The model snapshot remains `d32e972dd4315f1dc3f6be28fb2aab0ab3e80358`.

The observed machine load was about 31 during the old failures and about 2 before current checks. That is a possible contributor, not a confirmed cause: current CPU saturation did not recreate the fault. New probe identities exercised costly model preparation without deleting the user's shared caches; they do not establish that every system-wide Core ML cache was cold.

## Source and upstream investigation

In the pinned streaming manager the encoder uses async prediction; RNNT decoder and joint stages use synchronous calls. No static input-shape mismatch or obvious borrowed-buffer lifetime defect was found. The direct sync/async comparison found no deterministic difference. [Pinned streaming manager](https://github.com/FluidInference/FluidAudio/blob/503b4bd1bbf7220882de39fe8ae6716aae4132da/Sources/FluidAudio/ASR/Parakeet/Unified/StreamingUnifiedAsrManager.swift#L355), [decoder](https://github.com/FluidInference/FluidAudio/blob/503b4bd1bbf7220882de39fe8ae6716aae4132da/Sources/FluidAudio/ASR/Parakeet/Unified/UnifiedRnntDecoder.swift)

Related upstream reports identify several distinct mechanisms:

- MacParakeet's macOS 14 fixes serialize long-file **TDT** chunks and change that model's encoder routing. They explicitly exclude Unified. Applying those changes to INT8 Unified would be speculative; the pinned SDK also warns against routing its INT8 encoder to the GPU. [Chunk serialization](https://github.com/moona3k/macparakeet/pull/998), [TDT encoder routing](https://github.com/moona3k/macparakeet/pull/1089)
- FluidAudio's concurrent ASR/diarization issue was resolved in the reporting integration by serialization. This investigation disables speaker detection and runs the native probes sequentially, so it does not reproduce that integration's concurrent call pattern. [Issue 661](https://github.com/FluidInference/FluidAudio/issues/661)
- A separate application reports the same outer async error with underlying E5RT code 10 identifying an encoder operation timeout. That makes a runtime timeout plausible, but its measurements do not diagnose this machine's original failures or prove that warming/retrying fixes them. [ASR measurements in issue 678](https://github.com/drakulavich/kesha-voice-kit/issues/678)

## Fix boundary and retained diagnostics

No production patch passed a failing-before/passing-after check because the original failure did not recur. Successful reruns must not be described as a fix. The remaining blocker is capturing a current failing prediction and its underlying NSError, then confirming one causal change against that same case.

Private evidence and runnable probes are retained under:

```text
~/.local/state/dotfiles/coreml-fix-2026-11-10/
```

`baseline.json`, `under-load.json`, and the original interleaving log record full-app checks. `stream-probe.swift` captures the model stage, input geometry, compute policy, timing, NSError domain/code, and full underlying `userInfo` if prediction fails. It can compare synchronous and asynchronous execution with the pinned mel extractor. The original failure records remain under the earlier `voice-engine-2026-11-10` evidence directory.

Handy's GGUF path remains the verified option. The Core ML CLI works in the current checks, with the historical intermittent failure still unresolved.

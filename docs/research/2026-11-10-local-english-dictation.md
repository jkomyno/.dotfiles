# Local English dictation on Apple M1 Pro

Research snapshot: 2026-11-10. Target: M1 Pro, 10 CPU cores, 32 GiB unified memory, short English voice prompts. Source research only: no installation, model download, app upgrade, or settings change. No model was timed on this machine.

Subsequent deployment on the same date: Handy was upgraded to 0.10.0 and the user selected Unified GGUF. The model was downloaded, made the managed and live default, and tested with Handy's default-model CLI path before and after deleting the retired TDT v3 ONNX directory (670,624,862 logical bytes). Existing live-only settings were preserved. The Core ML comparison and its unresolved historical failures are recorded in the [compatibility report](2026-11-10-coreml-dictation-apps.md) and [follow-up investigation](2026-11-10-coreml-failure-investigation.md). The original research snapshot below is retained as dated evidence.

## Recommendation

**For a current Handy installation, shortlist Parakeet Unified English 0.6B for responsiveness and Qwen3-ASR 1.7B for accuracy.** These are conditional recommendations, supported by Handy's own runtime measurements and English benchmark, rather than a universal ranking. Handy's current recommendations make the same distinction. Its published wait estimates use a Ryzen 4750U, so they do not predict M1 Pro wait times. [Handy recommendations](https://models.handy.computer/recommendations/)

The installed Handy version was independently checked in this session as **0.7.9**, with Parakeet TDT v3 selected. **Handy 0.10.0, released November 2, is a material prerequisite for the newer catalog recommendation:** it changes to transcribe.cpp/GGUF and removes the old ONNX backend. Its release-tag catalog includes both recommended models. Keeping the existing v3 setup is reasonable until an upgrade and comparison are wanted; research did not perform either. [Release](https://github.com/cjpais/Handy/releases/tag/v0.10.0), [released catalog](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/src/catalog/catalog.json)

For English-only use on the older setup, **Parakeet v2 is a credible comparison against v3**. V2 is English-only; v3 adds 25 European languages. More languages and a higher version number do not establish better English dictation. NVIDIA dates v2 May 1, 2025 and v3 August 14, 2025; both use CC-BY-4.0. [V2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2), [V3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)

## Evidence closest to Handy

Handy's engine publishes the following **English FLEURS test-split WER at Q8_0**. Lower is better. These are read-speech results from one dataset, not scores for spontaneous technical prompts. The speed columns deliberately retain their actual AMD hardware label. [Benchmark](https://models.handy.computer/)

| Model | English WER | Ryzen 4750U GPU / CPU, × realtime |
| --- | ---: | ---: |
| Qwen3-ASR 1.7B | 3.23% | 4.1 / 2.5 |
| Parakeet Unified English 0.6B | 3.99% | 25.3 / 14.0 |
| Parakeet TDT 0.6B v2 | 4.11% | 27.4 / 14.3 |
| Parakeet Ultra | 4.26% | 23.0 / 13.3 |
| Whisper large-v3-turbo | 4.38% | 3.1 / 1.4 |
| Parakeet TDT 0.6B v3 | 4.83% | 25.1 / 13.7 |
| Cohere Transcribe March 2026 | 5.08% | 8.1 / 4.3 |
| Voxtral Mini 4B Realtime | 6.27% | 0.8 / 0.6 |
| Nemotron English streaming 0.6B | 6.43% | 27.1 / 13.6 |

Handy's engine also reports **Apple M4 Max Metal**, Q8_0, warmed compute-only measurements: Unified takes 59 ms for an 11.0 s sample and 155 ms for 35.3 s; Qwen 1.7B takes 243 ms and 959 ms respectively. These are means of three runs after one warmup, transcribe.cpp `77b0c93`, September 14. They show the speed tradeoff on Apple Silicon but exclude the full app path and cannot be relabeled M1 Pro latency. [Unified runtime card](https://github.com/handy-computer/transcribe.cpp/blob/main/docs/models/parakeet-unified-en-0.6b.md), [Qwen runtime card](https://github.com/handy-computer/transcribe.cpp/blob/main/docs/models/qwen3-asr-1.7b.md)

Qwen's engine card uses Whisper-style English normalization and jiwer for LibriSpeech scoring. On English FLEURS, Qwen Q5_K_M scores 3.43% versus Q8_0's 3.23%, with overlapping reported uncertainty; quantization effects differ across languages. **32 GiB does not force aggressive quantization of these small candidates.** That is a capacity judgment from their weight sizes, not a measurement of working memory. [Qwen quantization results](https://models.handy.computer/models/Qwen3-ASR-1.7B/)

## Model choices and practical availability

Approximate sizes below are **downloaded weights**, not peak memory. GGUF sizes are decimal GB from the released Handy catalog, rounded; original names can count parameters differently from the exported whole model. All listed candidates have public weights, with differing license terms. [Released catalog](https://github.com/cjpais/Handy/blob/v0.10.0/src-tauri/src/catalog/catalog.json)

| Candidate | Release / license | Weight size and use |
| --- | --- | --- |
| Parakeet Unified English 0.6B | Apr 7, 2026; NVIDIA Open Model License | Handy Q8 ~0.73 GB. English, punctuated text, offline and buffered streaming. |
| Qwen3-ASR 1.7B / 0.6B | Jan 2026; Apache-2.0 | Handy Q8 ~2.19 / 0.85 GB. Accuracy candidate / smaller alternative. |
| Cohere Transcribe 2B | Mar 26, 2026; Apache-2.0 | Handy Q8 ~2.41 GB; Q5 ~1.77 GB. Offline, choose English. |
| Moonshine Streaming Medium | Feb 2026 family; MIT for English | 245M upstream; Handy Q8 ~0.30 GB. Tiny/Small trade accuracy for size. |
| Nemotron English streaming 0.6B | Jan 5, updated Mar 12–13, 2026; NVIDIA Open Model License | Handy Q8 ~0.73 GB. Cache-aware streaming. |
| Nemotron 3.5 streaming 0.6B | Jun 4, 2026; OpenMDW-1.1 | Handy Q8 ~0.75 GB. Multilingual extension, not NVIDIA's English-only recommendation. |
| Voxtral Mini 4B Realtime | Feb 4, 2026; Apache-2.0 | Handy Q8 ~4.73 GB. Native streaming, larger model. |
| Whisper large-v3-turbo | Oct 1, 2024; MIT | 809M; Handy Q8 ~0.89 GB. Mature fallback, offline recognition. |

**Unified:** NVIDIA's owning card says NVIDIA Open Model License, while Handy's catalog labels it CC-BY-4.0. Treat the upstream license as authoritative. Streaming recomputes left context and trades accuracy for lookahead; the advertised 160 ms is an algorithm setting, not measured final-paste latency. [NVIDIA Unified card](https://huggingface.co/nvidia/parakeet-unified-en-0.6b)

**Qwen:** the family supports 30 languages plus 22 Chinese dialects. Upstream has streaming and offline inference, but Handy's released GGUF catalog marks its Qwen port as non-streaming. Qwen's advertised ~2000× throughput is at concurrency 128, not one laptop utterance. The report appeared January 29; native Transformers support followed in June. [Report](https://arxiv.org/abs/2601.21337), [official implementation](https://github.com/QwenLM/Qwen3-ASR), [model card](https://huggingface.co/Qwen/Qwen3-ASR-1.7B)

**Cohere:** its eight-set English Open ASR result is 5.42% average WER, versus Qwen's 5.76% and Whisper large-v3's 7.44% in the same card. This is good evidence for a serious accuracy comparison, and explains Handy's older documentation recommending it. It does not override Handy's different FLEURS result. Cohere lacks timestamps and explicit language detection; its card warns that silence/non-speech can cause hallucinations and recommends VAD. [Cohere card](https://huggingface.co/CohereLabs/cohere-transcribe-03-2026), [older Handy docs](https://handy.computer/docs/models)

**Moonshine:** prefer the streaming family when low finalization delay matters. Upstream reports English Medium 6.65% average WER across eight sets for its floating reference; quantized scores can regress. Its response-latency benchmark starts when VAD decides a phrase ended and compares CPU faster-whisper against an already-running stream. It is not a comparison against Metal Whisper, and VAD endpoint detection itself adds delay. [Available models](https://github.com/moonshine-ai/moonshine/blob/main/docs/models/available-models.md), [benchmark procedure](https://github.com/moonshine-ai/moonshine/blob/main/docs/using/benchmarks.md), [February report](https://arxiv.org/abs/2602.12241)

**Nemotron:** distinguish January, updated March English, and June multilingual checkpoints. The March English card reports eight-set mean WER 6.93% at 1.12 s chunks, degrading to 8.43% at 80 ms, after whisper-normalizer 0.1.12. NVIDIA explicitly recommends the English model for English-only work over June's multilingual extension. Their H100 concurrency plots do not predict M1 speed. [English card](https://huggingface.co/nvidia/nemotron-speech-streaming-en-0.6b), [June card](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b)

**Voxtral:** Realtime is the open-weight model; the separate Mini Transcribe V2 service must not be substituted in comparisons. Mistral's 480 ms and sub-200 ms claims are configurable streaming delays. Accuracy changes with delay. For short English push-to-talk, its larger size and weaker Handy English score make it a secondary candidate. [Mistral release](https://mistral.ai/news/voxtral-transcribe-2/)

**Whisper turbo:** cuts large-v3's decoder from 32 layers to four, improving speed with some accuracy loss. It remains a useful mature comparison, especially if familiar behavior matters, rather than the automatic English winner in 2026. [Official announcement](https://github.com/openai/whisper/discussions/2363), [MIT model card](https://huggingface.co/openai/whisper-large-v3-turbo)

## Newer contenders checked

- **Parakeet Ultra / Redux, September 22:** Ultra is a full-precision v3 derivative claiming 5.80% versus 6.26% across seven English sets. Redux uses ternary encoder weights, 178 MB, with a modest English accuracy loss and a larger noise penalty. Its Apple result is **M2 Air**, 50 LibriSpeech dev-clean utterances: Photon 38× CPU / 43× GPU, not M1 Pro. Ultra is curated in Handy 0.10; Redux is an alternative runtime experiment, not the first accuracy recommendation. Both cards say CC-BY-4.0. [Release](https://moondream.ai/blog/introducing-parakeet-redux-and-ultra), [Ultra](https://huggingface.co/moondream/parakeet-ultra), [Redux](https://huggingface.co/moondream/parakeet-redux)
- **IBM Granite Speech 5.0 TurboCTC:** August 25 English release, October 21 multilingual update; 470M, Apache-2.0, non-autoregressive greedy decoding. IBM reports improved English average WER 5.51% versus 5.78%. Handy's catalog still describes its pinned conversion as English, so do not transfer the newer checkpoint's results to that older artifact. The separate `-nc` model has noncommercial terms. [Current IBM card](https://huggingface.co/ibm-granite/granite-speech-5.0-470m-turboctc)
- **IBM Granite Speech 5.0 2B, October 20:** newer accuracy/context-biasing candidate, Apache-2.0; up to 2000 keywords. Its own card documents MLX Audio >=0.5.9 and llama.cpp/GGUF on macOS. Handy 0.10 includes 4.1, not this 5.0 2B model; this is a separate-runtime comparison, without an established M1 Pro latency advantage. [IBM card](https://huggingface.co/ibm-granite/granite-speech-5.0-2b)
- **Nemotron 3.5 Transcribe 30B-A4B, October 28:** latest substantial offline contender; 34B total including encoder, ~4.3B active, OpenMDW-1.1, 40 languages. Its nine-set English mean is 4.71%; that includes different datasets from older eight-set tables. BF16 weights alone exceed 32 GiB. MLX/quantized forms exist, but this is not a practical first dictation choice without local evidence; NVIDIA's very low latency claims use RTX PRO 6000 Blackwell and optimized speculative decoding. [NVIDIA card](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Transcribe-30B-A4B), [MLX support](https://github.com/Blaizzy/mlx-audio)

MLX Audio currently provides implementations for Parakeet, Qwen3-ASR, Moonshine, Nemotron and Voxtral Realtime, including quantized choices. This establishes an Apple Silicon route outside Handy, not that its behavior or speed equals Handy's GGUF implementation. Cohere also lists MLX Audio in its supported ecosystem. [MLX Audio](https://github.com/Blaizzy/mlx-audio), [Cohere ecosystem](https://huggingface.co/CohereLabs/cohere-transcribe-03-2026#ecosystem-support-)

## What a local comparison must establish

Use the same representative English recordings: short and long prompts, accent, room noise, identifiers, acronyms, proper names, numbers and punctuation. Compare correction effort and missed/added words, then median and slowest release-to-paste delay with warm and cold models. Keep sample rate, VAD, vocabulary hints and post-processing identical. This is a suggested evaluation, not work performed.

Do not combine FLEURS scores, eight-set vendor means, newer nine-set means and individual LibriSpeech scores into one ranking. The Open ASR evaluation repository currently standardizes local-model runs on **one H200 141 GB**, with model-specific Docker images; its throughput is not laptop latency. Text normalization can conceal formatting differences that matter in prompts. [Leaderboard methodology](https://github.com/huggingface/open_asr_leaderboard)

## App compatibility and this machine's setup

Handy inserts a transcript into the focused text field. Therefore, pi, Claude Code and Codex can receive dictation through their normal terminal prompt; they do not require individual Handy integrations. This is compatibility inferred from the input mechanism, not a microphone-to-agent smoke test performed here. Focus the agent's input, record, stop, review the resulting text, then submit. Handy's macOS documentation recommends clipboard Cmd+V for general use; Direct Input instead types characters and can misbehave with non-US keyboard layouts. [Paste methods](https://handy.computer/docs/paste-methods)

The installed app is 0.7.9. The managed settings and both local settings copies select `parakeet-tdt-0.6b-v3`, automatic language selection, Direct Input, no automatic submission, no post-processing, and `model_unload_timeout = "never"`. Keeping the model loaded avoids repeated model loading, at a memory cost. If Direct Input is working, changing it is unnecessary; clipboard Cmd+V is a reasonable comparison for long prompts or layout problems. Keeping automatic submission off allows correction of names, identifiers and commands before submission. No setting was changed during this research.

## GitHub, Product Hunt and X checks

- **GitHub:** the repository has 38,176 stars, is not archived, and was pushed on November 7. The latest stable release is 0.10.0, published November 2. This supports continued activity, rather than establishing recognition quality. The release changes the transcription engine and model format, so older Handy reviews may describe a different implementation. [Repository](https://github.com/cjpais/Handy), [release](https://github.com/cjpais/Handy/releases/tag/v0.10.0)
- **Product Hunt:** Handy has 5.0/5 from six reviews, 85 followers, and 103 launch upvotes. This is a small positive user sample, not strong comparative evidence. [Product page](https://www.producthunt.com/products/handy-4)
- **X:** live trends could not be verified. Composio's X search capability was discovered, but its X connection requires authorization. Public indexed X searches did not produce usable current posts about the shortlisted models; a generic dictation trend summary could not be opened. No conclusion about November X popularity is supported by these checks.

Recommendation for this machine: upgrade Handy separately when authorized, then start with the released Q8 Parakeet Unified English model. Compare Qwen3-ASR 1.7B if correcting recognition errors costs more time than waiting for transcription. Both fit comfortably in the machine's 32 GiB in terms of weight size; actual runtime memory and release-to-paste latency remain unmeasured.

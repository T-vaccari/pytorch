# gfx1010 ROCm release-candidate build record

This document records the validated PyTorch stack for the AMD Radeon RX 5600 XT
(`gfx1010`). This is an experimental fork configuration, not an upstream-supported
PyTorch or ROCm target.

## Isolation rules

Keep these layers separate:

1. immutable source worktrees;
2. dedicated build environments;
3. versioned wheel artifacts;
4. the release-candidate runtime environment;
5. the existing `ml` environment.

The validated build did not install into or modify `ml`. At the end of the
release-candidate validation, `ml` still imported
`torch 2.8.0a0+gitba56102` from its own `site-packages` directory.

Do not copy shared objects into an environment, add a source checkout through a
`.pth` file, or reuse an existing CMake build directory. Build wheels in clean
worktrees and install those wheels into a separate environment.

## Source provenance

| Component | Repository / revision |
| --- | --- |
| PyTorch fork | `https://github.com/T-vaccari/pytorch` |
| PyTorch branch | `gfx1010-rocm` |
| Validated PyTorch head | `6b6c29a2e3581af06f0cdb29a09bfe27cdd3b29f` |
| Upstream base | `ba56102387ef21a3b04b357e5b183d48f0afefc7` (v2.8.0) |
| Kineto fork | `https://github.com/T-vaccari/kineto.git` |
| Kineto revision | `bc37fab44c422b9b2e6d8f91367e9fc7b353a393` |
| gfx1010 kernels | `https://github.com/T-vaccari/gfx1010-kernels` |
| gfx1010 kernels revision | `ecc5ece0f08de4287fb9fe97219268b62d1210ae` |
| TorchAudio source | `https://github.com/pytorch/audio`, tag v2.8.0, `6e1c7fe9ff6d82b8665d0a46d859d3357d2ebaaa` |
| TorchVision source | `https://github.com/pytorch/vision`, tag v0.23.0, `824e8c8726b65fd9d5abdc9702f81c2b0c4c0dc8` |

The validated history is split across focused pull requests:

| Repository | Pull request | Merge commit |
| --- | --- | --- |
| PyTorch fork | [#4: Fix ROCm multiblock topk regression](https://github.com/T-vaccari/pytorch/pull/4) | `5257dd3a0980e3731c46848a233e7ce55a80ba66` |
| PyTorch fork | [#5: Record the gfx1010 build and Triton 3.4 validation](https://github.com/T-vaccari/pytorch/pull/5) | `6b6c29a2e3581af06f0cdb29a09bfe27cdd3b29f` |
| PyTorch fork | [#6: Fix torch.compile with Triton 3.5](https://github.com/T-vaccari/pytorch/pull/6) | `894c0526688e8f6713bc0c4aa20ee6546737af4a` |
| PyTorch fork | [#7: Fix Triton 3.5 ASTSource compatibility](https://github.com/T-vaccari/pytorch/pull/7) | `c3dfaef65658ce29120b32fa53f8bcefb0d2dc64` |
| gfx1010 kernels | [#2: Test GPT-2 D64 batch-six attention backward](https://github.com/T-vaccari/gfx1010-kernels/pull/2) | `42d1a531a57cb82ceaf80ba98bc80eb7415ab812` |
| gfx1010 kernels | [#3: Add compiled GPT-2 FP16 and chunked attention paths](https://github.com/T-vaccari/gfx1010-kernels/pull/3) | `1be3c34f69ef93db47304461f7bc8b1613d2ad73` |
| gfx1010 kernels | [#4: Optimize GPT-2 D64 attention backward for B<=4](https://github.com/T-vaccari/gfx1010-kernels/pull/4) | `ecc5ece0f08de4287fb9fe97219268b62d1210ae` |

Clone the fork rather than upstream PyTorch and initialize every submodule:

```bash
git clone --branch gfx1010-rocm --recurse-submodules \
  https://github.com/T-vaccari/pytorch.git
cd pytorch
git submodule sync --recursive
git -c submodule.fetchJobs=12 submodule update --init --recursive --jobs 12
git status --short
git rev-parse HEAD
git submodule status --recursive
```

The source worktree must be clean and at the validated head before configuring.

## Validated toolchain

| Component | Value |
| --- | --- |
| GPU | AMD Radeon RX 5600 XT (`gfx1010:xnack-`) |
| Host OS | Ubuntu 22.04 |
| ROCm root | `/opt/rocm-7.2.2` |
| HIP runtime | `7.2.53211-671d39a71e` |
| Python | 3.10.20 |
| PyTorch wheel version | `2.8.0a0+git6b6c29a` |
| Triton | 3.4.0 |
| Build type | Release |
| Generator | Ninja 1.13.0 |
| CMake | 4.3.2 |
| C/C++ compiler | GCC 11.4.0 (`/usr/bin/cc`, `/usr/bin/c++`) |
| GPU target | `gfx1010` |
| Build parallelism | `MAX_JOBS=12` |

## Clean PyTorch build

The validated build used a dedicated environment named
`ml-gfx1010-rc-build`. Configure and build only from a fresh worktree and an
empty build directory:

```bash
export PATH=/opt/rocm-7.2.2/bin:$CONDA_PREFIX/bin:$PATH
export ROCM_HOME=/opt/rocm-7.2.2
export PYTORCH_ROCM_ARCH=gfx1010
export MAX_JOBS=12
export CMAKE_BUILD_TYPE=Release
export USE_ROCM=1
export USE_CUDA=0
export USE_FLASH_ATTENTION=0
export USE_MEM_EFF_ATTENTION=0
export USE_KINETO=1
export USE_DISTRIBUTED=0
export USE_NCCL=0
export BUILD_TEST=0
export CMAKE_POLICY_VERSION_MINIMUM=3.5
python setup.py bdist_wheel
```

`USE_FLASH_ATTENTION=0` and `USE_MEM_EFF_ATTENTION=0` are intentional. The
native AOTriton gfx1010 experiment produced incorrect backward gradients. The
validated optimized SDPA implementation lives in `gfx1010-kernels` and is
tested independently from the PyTorch build.

## Validated artifacts

| Artifact | SHA256 |
| --- | --- |
| `torch-2.8.0a0+git6b6c29a-cp310-cp310-linux_x86_64.whl` | `aebf54ecb04b5dd2fb20fae3facd21b5127278caaf790a7a742b5a965004c2bb` |
| `gfx1010_kernels-0.4.0-cp310-cp310-linux_x86_64.whl` | `a5e7847640364e6dba8aa36d4c0142adf33763acf09cfc794634610929da3fd5` |
| `torchaudio-2.8.0+gfx1010.rocm72-cp310-cp310-linux_x86_64.whl` | `8ac09e676b5034832396f40b0e3a9ce5c07dd070e415cf2b774fe2f29721ebf0` |
| `torchvision-0.23.0+gfx1010.rocm72-cp310-cp310-linux_x86_64.whl` | `79b2540a62ab60a27fa1b44d499390680e19c9bb8dd764559e10744a8ebf25aa` |
| `gfx1010_kernels_autoload.pth` | `d277b83aba3961db900a891ee0f346aad3207e84c80fd5b8977f418adcaa4ef5` |

The artifact names and hashes are part of the release-candidate identity. Do
not substitute an older wheel with the same package name.

## Companion wheels

TorchAudio was built from the matching v2.8.0 source in a dedicated
`ml-gfx1010-rc-audio-build` environment. The wheel pins the exact custom
PyTorch version and deliberately excludes optional media components:

```bash
export BUILD_VERSION=2.8.0+gfx1010.rocm72
export PYTORCH_VERSION=2.8.0a0+git6b6c29a
export USE_ROCM=1
export USE_CUDA=0
export BUILD_SOX=0
export BUILD_RIR=0
export BUILD_RNNT=0
export BUILD_ALIGN=0
export USE_FFMPEG=0
python setup.py bdist_wheel
```

TorchVision was built from the matching v0.23.0 source in a dedicated
`ml-gfx1010-rc-vision-build` environment. That build environment pins
`setuptools==80.9.0`: setuptools 82 no longer provides `pkg_resources`, which
the v0.23.0 build scripts still import. This pin is build-only and is not
required in the release-candidate runtime environment.

```bash
export PATH=/opt/rocm-7.2.2/bin:$CONDA_PREFIX/bin:$PATH
export ROCM_HOME=/opt/rocm-7.2.2
export PYTORCH_ROCM_ARCH=gfx1010
export FORCE_CUDA=1
export MAX_JOBS=12
export BUILD_VERSION=0.23.0+gfx1010.rocm72
export PYTORCH_VERSION=2.8.0a0+git6b6c29a
export TORCHVISION_USE_PNG=1
export TORCHVISION_USE_JPEG=1
export TORCHVISION_USE_NVJPEG=0
export TORCHVISION_USE_FFMPEG=0
python setup.py bdist_wheel
```

## Release-candidate environment

The validated runtime environment is `ml-gfx1010-rc`. Install only the
versioned wheels and install `gfx1010-kernels` non-editably. Inspect
`site-packages` first and remove or disable source-backed `.pth` files from the
new RC environment only:

```bash
python -m pip install --no-deps --force-reinstall \
  torch-2.8.0a0+git6b6c29a-cp310-cp310-linux_x86_64.whl \
  gfx1010_kernels-0.4.0-cp310-cp310-linux_x86_64.whl \
  torchaudio-2.8.0+gfx1010.rocm72-cp310-cp310-linux_x86_64.whl \
  torchvision-0.23.0+gfx1010.rocm72-cp310-cp310-linux_x86_64.whl
python -m pip check
```

The global SDPA patch is RC-local. Copy the packaged autoload asset only to
the RC `site-packages` directory:

```bash
cp deploy/gfx1010_kernels_autoload.pth \
  "$CONDA_PREFIX/lib/python3.10/site-packages/gfx1010_kernels_autoload.pth"
```

In a fresh Python process, ordinary code can continue using
`torch.nn.functional.scaled_dot_product_attention`. Supported gfx1010 shapes
dispatch to the custom implementation; unsupported shapes retain the PyTorch
math fallback. No source checkout is imported at runtime.

## Validation record

The release candidate passed the following checks on the RX 5600 XT:

- ROCm `topk` CPU parity for batches 2 and 5, with `k=2` and `k=50`;
- `torch.compile` forward and backward smoke tests;
- explicit and globally patched Flash Attention forward/backward at
  `B=2, H=12, T=1024, D=64`, causal FP16;
- Flash Attention correctness against forced PyTorch math for B1/B2/B4 across
  three seeds: 9/9 cases, no non-finite values, worst absolute error
  `0.001953125`;
- `gfx1010-kernels` full suite: 186 tests passed;
- Flash Attention memory growth linear in batch size, without a persistent
  full `T x T` attention matrix;
- TorchAudio import, CPU `MelSpectrogram`, and GPU resampling;
- TorchVision import plus CPU and GPU operator smoke tests;
- imports for NumPy, SciPy, scikit-learn, pandas, Matplotlib, Seaborn,
  Transformers/GPT-2, Tokenizers, Datasets, Accelerate, tiktoken,
  SentencePiece, Pillow and ipykernel;
- `pip check`: no broken requirements.

The GPT-2 training benchmark used `B=2`, `T=1024`, effective batch 16384,
eight accumulation steps and `torch.compile`. Excluding the compile-heavy
first step, 14 hot steps averaged **3819.63 tokens/s** (minimum 3816.39,
maximum 3821.56), with no attention fallback warning. The benchmark log SHA256
is `8022c51acd9db88018171938de9367ffbd3e61c91dc7748bb694eeb7540fcc78`.

## Fixed regressions

### ROCm topk

The ROCm multi-block `topk` path corrupted values for GPT-2-shaped tensors
when `B >= 2`. The branch disables only that faulty ROCm path and retains the
standard implementation. The clean wheel contains the fix and passed exact CPU
parity checks.

### torch.compile and Triton

The branch contains compatibility fixes for both the moved
`triton.runtime.cache.triton_key` path and the Triton 3.5
`ASTSource.make_ir` signature. The release candidate intentionally freezes
Triton 3.4.0, which passed forward/backward compilation and the GPT-2 workload.

## Known limitations

- Native AOTriton and memory-efficient SDPA are disabled. Use the validated
  `gfx1010-kernels` dispatch or PyTorch math fallback.
- The custom attention path supports a validated subset of shapes and dtypes;
  unsupported calls must fall back rather than being forced.
- `torch.compile` around the Python/Triton attention dispatcher currently has
  four Dynamo graph breaks. Output and gradients match eager execution.
- GPU `torch.abs()` on a `complex64` tensor fails during HIPRTC compilation on
  this build. A minimal reproducer is:

  ```python
  import torch

  x = torch.randn(128, device="cuda", dtype=torch.complex64)
  x.abs()
  ```

  This also affects GPU TorchAudio transforms that internally take the
  magnitude of a complex tensor. CPU `MelSpectrogram` and GPU real-valued
  resampling pass. Treat this as a separate PyTorch HIPRTC issue; do not patch
  it with library symlinks or by replacing the validated ROCm runtime.

## Promotion rule

Keep `ml-gfx1010-rc` separate until real workloads have exercised it. Promote
by rebuilding or cloning from versioned artifacts, never by modifying `ml` in
place. A failed optional component should be repaired as its own wheel and
revalidated; it is not a reason to mix source trees or copy binary extensions
between environments.

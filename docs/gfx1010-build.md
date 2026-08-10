# gfx1010 ROCm build record

This is an experimental PyTorch build for the AMD Radeon RX 5600 XT
(`gfx1010`). It is not an upstream-supported configuration.

## Source provenance

- Fork: `https://github.com/T-vaccari/pytorch`
- Branch: `gfx1010-rocm`
- Recorded head: `4b4e8fa4c5d5fa939ac44794e2ec1c66afe60286`
- Upstream base: `ba56102387ef21a3b04b357e5b183d48f0afefc7` (PyTorch v2.8.0)
- Kineto submodule: `https://github.com/T-vaccari/kineto.git`, revision
  `bc37fab44c422b9b2e6d8f91367e9fc7b353a393`

Clone the fork, rather than upstream PyTorch, and initialize every submodule:

```bash
git clone --branch gfx1010-rocm --recurse-submodules https://github.com/T-vaccari/pytorch.git
cd pytorch
git submodule sync --recursive
git submodule update --init --recursive
```

## Recorded working configuration

| Component | Value |
| --- | --- |
| GPU | AMD Radeon RX 5600 XT (`gfx1010`) |
| Host OS | Ubuntu 22.04 |
| ROCm/HIP runtime | 7.2.53211 |
| Python | 3.10.20 |
| Installed PyTorch | `2.8.0a0+gitba56102` |
| Build type | Release |
| Generator | Ninja 1.13.0 |
| CMake | 4.3.2 |
| C++ compiler | `/usr/bin/c++` (GCC 11.4.0) |
| ROCm root | `/opt/rocm-7.2.2` |
| GPU target | `gfx1010` |
| Essential options | `USE_ROCM=ON`, `USE_CUDA=0`, `BUILD_TEST=OFF` |

Run CMake and Ninja from the `ml` conda environment. The system-wide tools are
older and are not the tools that generated the recorded build cache:

```bash
conda run -n ml cmake --version
conda run -n ml ninja --version
```

The cache uses `/mnt/data/miniforge3`; on this host that is the canonical data
path. Do not replace it blindly with a different Python prefix in an existing
build directory. Configure a fresh build directory when reproducing the build.

## Reproduction status

The source revision, submodule pin, toolchain, and CMake options above are
recorded from the installed working build. A clean build from a new directory
has **not yet been validated**. The original invocation was not retained, so
do not claim a new build is equivalent until it passes the smoke test below.

Before starting a replacement build, record the exact environment and command:

```bash
env | rg '^(PATH|CONDA_PREFIX|ROCM|HIP|PYTORCH|CMAKE|CC|CXX)='
git rev-parse HEAD
git submodule status --recursive
```

After a clean build, verify the artifact before replacing the active `ml`
environment:

```bash
python -c 'import torch; print(torch.__version__); print(torch.version.hip); print(torch.cuda.get_device_name(0))'
```

## Known functional limitation

HIP `torch.topk` is corrupted for a `(B, 50257)` tensor when `B >= 2` on this
build. The failure is isolated to the multi-block selection path; `softmax` and
GPU `torch.sort` are correct for the same input. Details, a minimal reproducer,
and the safe CPU sampling workaround are tracked in issue #1.

Do not use GPU `topk` or `multinomial` for GPT-2 generation until a candidate
fix is validated in a separate build directory. Training forward/backward does
not use this sampling path.

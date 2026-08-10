# gfx1010 ROCm build record

This is an experimental PyTorch build for the AMD Radeon RX 5600 XT
(`gfx1010`). It is not an upstream-supported configuration.

## Source provenance

- Fork: `https://github.com/T-vaccari/pytorch`
- Branch: `gfx1010-rocm`
- Recorded head: `5257dd3a0980e3731c46848a233e7ce55a80ba66`
- Upstream base: `ba56102387ef21a3b04b357e5b183d48f0afefc7` (PyTorch v2.8.0)
- Kineto submodule: `https://github.com/T-vaccari/kineto.git`, revision
  `bc37fab44c422b9b2e6d8f91367e9fc7b353a393`

Clone the fork, rather than upstream PyTorch, and initialize every submodule:

```bash
git clone --branch gfx1010-rocm --recurse-submodules https://github.com/T-vaccari/pytorch.git
cd pytorch
git submodule sync --recursive
git -c submodule.fetchJobs=12 submodule update --init --recursive --jobs 12
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

## Candidate build command

Build in a fresh worktree or build directory. This command deliberately leaves
the active `ml` environment untouched: it only uses its build tools.

```bash
MAX_JOBS=12 \
PYTORCH_ROCM_ARCH=gfx1010 \
AOTRITON_INSTALL_FROM_SOURCE=1 \
CMAKE_POLICY_VERSION_MINIMUM=3.5 \
conda run -n ml python setup.py build
```

`CMAKE_POLICY_VERSION_MINIMUM=3.5` is required with the recorded CMake 4.3.2,
because an external dependency still declares compatibility with pre-3.5 CMake.

`AOTRITON_INSTALL_FROM_SOURCE=1` is required on this host. The ROCm 7.0
prebuilt AOTriton archive selected by the build failed its pinned SHA-256
verification, so its binary must not be accepted or bypassed. The source path
builds the AOTriton revision pinned by PyTorch and receives `gfx1010` from
`PYTORCH_ROCM_ARCH`.

Flash Attention is an acceptance requirement for the final candidate. After a
successful build, verify both that AOTriton produced `gfx1010` images and that
PyTorch selects the Flash backend for causal FP16 SDPA with GPT-2 dimensions
(`B >= 1`, `H=12`, `T=1024`, `D=64`). A library being present is not sufficient.

## torch.compile dependency pin

The currently installed `ml` environment has Triton 3.5.1, while this PyTorch
source imports `triton.compiler.compiler.triton_key`, which is available in the
PyTorch CI-pinned Triton 3.4.0 but absent from 3.5.1. A clean isolated test with
Triton 3.4.0 compiled and ran a CUDA/HIP tensor function, including backward.

Do not replace Triton in `ml` while validating builds. A final candidate
environment must pin `triton==3.4.0` (or the exact commit in
`.ci/docker/ci_commit_pins/triton.txt`) and re-run the compile smoke test.

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

## Validated ROCm topk fix

The ROCm multi-block `topk` path corrupted values for a `(B, 50257)` tensor
when `B >= 2`. Commit `3a887fc9d0c` disables only that ROCm multi-block path;
the standard path remains available. The regression test covers batches 2 and
5 against a CPU reference, and manual HIP checks matched values and indices.

The fix is merged in this branch. It is not present in an older installed
PyTorch build until a newly validated candidate is installed.

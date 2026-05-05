# Building
Sunshine binaries are built using [CMake](https://cmake.org) and requires `cmake` > 3.25.

## Building Locally

### Compiler
It is recommended to use one of the following compilers:

| Compiler    | Version |
|:------------|:--------|
| GCC         | 13+     |
| Clang       | 17+     |
| Apple Clang | 15+     |

### Dependencies

#### Linux
Dependencies vary depending on the distribution. You can reference our
[linux_build.sh](https://github.com/LizardByte/Sunshine/blob/master/scripts/linux_build.sh) script for a list of
dependencies we use in Debian-based and Fedora-based distributions. Please submit a PR if you would like to extend the
script to support other distributions.

##### CUDA Toolkit
Sunshine requires CUDA Toolkit for NVFBC capture. There are two caveats to CUDA:

1. The version installed depends on the version of GCC.
2. The version of CUDA you use will determine compatibility with various GPU generations.
   At the time of writing, the recommended version to use is CUDA ~12.9.
   See [CUDA compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/index.html) for more info.

> [!NOTE]
> To install older versions, select the appropriate run file based on your desired CUDA version and architecture
> according to [CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)

#### macOS
You can either use [Homebrew](https://brew.sh) or [MacPorts](https://www.macports.org) to install dependencies.

##### Homebrew
```bash
dependencies=(
  "boost"  # Optional
  "cmake"
  "doxygen"  # Optional, for docs
  "graphviz"  # Optional, for docs
  "icu4c"  # Optional, if boost is not installed
  "miniupnpc"
  "ninja"
  "node"
  "openssl@3"
  "opus"
  "pkg-config"
)
brew install "${dependencies[@]}"
```

If there are issues with an SSL header that is not found:

@tabs{
  @tab{ Intel | ```bash
    ln -s /usr/local/opt/openssl/include/openssl /usr/local/include/openssl
    ```}
  @tab{ Apple Silicon | ```bash
    ln -s /opt/homebrew/opt/openssl/include/openssl /opt/homebrew/include/openssl
    ```
  }
}

##### MacPorts
```bash
dependencies=(
  "cmake"
  "curl"
  "doxygen"  # Optional, for docs
  "graphviz"  # Optional, for docs
  "libopus"
  "miniupnpc"
  "ninja"
  "npm9"
  "pkgconfig"
)
sudo port install "${dependencies[@]}"
```

#### Windows
First you need to install [MSYS2](https://www.msys2.org), then startup "MSYS2 UCRT64" and execute the following
commands.

##### Update all packages
```bash
pacman -Syu
```

##### Install dependencies
```bash
dependencies=(
  "git"
  "mingw-w64-ucrt-x86_64-boost"  # Optional
  "mingw-w64-ucrt-x86_64-cmake"
  "mingw-w64-ucrt-x86_64-cppwinrt"
  "mingw-w64-ucrt-x86_64-curl-winssl"
  "mingw-w64-ucrt-x86_64-doxygen"  # Optional, for docs... better to install official Doxygen
  "mingw-w64-ucrt-x86_64-graphviz"  # Optional, for docs
  "mingw-w64-ucrt-x86_64-MinHook"
  "mingw-w64-ucrt-x86_64-miniupnpc"
  "mingw-w64-ucrt-x86_64-nodejs"
  "mingw-w64-ucrt-x86_64-nsis"
  "mingw-w64-ucrt-x86_64-onevpl"
  "mingw-w64-ucrt-x86_64-openssl"
  "mingw-w64-ucrt-x86_64-opus"
  "mingw-w64-ucrt-x86_64-toolchain"
  "mingw-w64-ucrt-x86_64-nlohmann_json"
)
pacman -S "${dependencies[@]}"
```

##### Local release installer
Windows에서 릴리즈 패키지와 동일하게 동작하는 installer를 만들 때는 이 절차를 사용한다. 이 방식으로 만든 NSIS
installer에는 service helper, Start Menu shortcut, uninstall entry, firewall script, driver script, service autostart
등록이 포함된다.

아래 명령은 PowerShell, Git Bash, Visual Studio Developer Prompt가 아니라 반드시 **MSYS2 UCRT64**에서 실행한다.

```bash
cd /c/Study/2026.1/Apollo
rm -rf build
cmake -B build -G Ninja -S . -DCMAKE_BUILD_TYPE=Release
ninja -C build
cpack -G NSIS --config ./build/CPackConfig.cmake
```

생성된 installer 위치는 다음과 같다.

```bash
build/cpack_artifacts/Apollo.exe
```

`Apollo.exe`를 설치하면 릴리즈와 같은 폴더 구조와 Windows 통합 설정이 적용된다. `build` 폴더의 `sunshine.exe`를
직접 실행하는 것은 개발용 실행에 가깝다. 이 경우 console window가 뜰 수 있고, 그 창을 닫으면 Sunshine도 같이
종료된다. Installer는 `ApolloService`를 설정하고, Start Menu shortcut은 `sunshine.exe --shortcut`으로 실행되어
service가 console window 없이 Sunshine을 실행할 수 있게 한다.

CMake가 `failed recompaction: Permission denied` 오류로 실패하면, 이전에 중단된 build의 `ninja`, `c++`, `cc1plus`
프로세스가 아직 살아 있어서 `build.ninja`를 잡고 있을 수 있다. 다른 MSYS2 terminal을 닫거나 해당 프로세스를
종료한 뒤 `cmake` 명령을 다시 실행한다.

CMake가 MSYS2 package의 Boost를 사용하지 않고 Boost 다운로드로 fallback한다면, `mingw-w64-ucrt-x86_64-boost`가
설치되어 있는지 확인한다. 또한 `cmake/dependencies/Boost_Sunshine.cmake`에서 허용하는 Boost version 조건이 현재
MSYS2에 설치된 Boost package보다 너무 좁게 고정되어 있지 않은지도 확인한다.

### Clone
Ensure [git](https://git-scm.com) is installed on your system, then clone the repository using the following command:

```bash
git clone https://github.com/ClassicOldSong/Apollo.git --recurse-submodules
cd Apollo
mkdir build
```

### Build

```bash
cmake -B build -G Ninja -S .
ninja -C build
```

> [!TIP]
> Available build options can be found in
> [options.cmake](https://github.com/LizardByte/Sunshine/blob/master/cmake/prep/options.cmake).

### Package

@tabs{
  @tab{Linux | @tabs{
    @tab{deb | ```bash
      cpack -G DEB --config ./build/CPackConfig.cmake
      ```}
    @tab{rpm | ```bash
      cpack -G RPM --config ./build/CPackConfig.cmake
      ```}
  }}
  @tab{macOS | @tabs{
    @tab{DragNDrop | ```bash
      cpack -G DragNDrop --config ./build/CPackConfig.cmake
      ```}
  }}
  @tab{Windows | @tabs{
    @tab{Installer | ```bash
      cpack -G NSIS --config ./build/CPackConfig.cmake
      ```}
    @tab{Portable | ```bash
      cpack -G ZIP --config ./build/CPackConfig.cmake
      ```}
  }}
}

### Remote Build
It may be beneficial to build remotely in some cases. This will enable easier building on different operating systems.

1. Fork the project
2. Activate workflows
3. Trigger the *CI* workflow manually
4. Download the artifacts/binaries from the workflow run summary

<div class="section_buttons">

| Previous                              |                            Next |
|:--------------------------------------|--------------------------------:|
| [Troubleshooting](troubleshooting.md) | [Contributing](contributing.md) |

</div>

<details style="display: none;">
  <summary></summary>
  [TOC]
</details>

# 添加 LLVM 软件源并安装最新的工具链
wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
echo "deb http://apt.llvm.org/noble/ llvm-toolchain-noble main" | sudo tee /etc/apt/sources.list.d/llvm.list
echo "deb-src http://apt.llvm.org/noble/ llvm-toolchain-noble main" | sudo tee -a /etc/apt/sources.list.d/llvm.list
sudo apt update && sudo apt upgrade -y

# 安装 LLVM 和 Clang 相关工具
sudo apt install -y bolt-20 clang-20 clang-20-doc clang-format-20 clang-tidy-20       \
                    clang-tools-20 clangd-20 flang-20 libbolt-20-dev libc++-20-dev    \
                    libc++-20-dev-wasm32 libc++abi-20-dev libc++abi-20-dev-wasm32     \
                    libclang-20-dev libclang-common-20-dev libclang-rt-20-dev         \
                    libclang-rt-20-dev-wasm32 libclang-rt-20-dev-wasm64               \
                    libclang1-20 libclc-20-dev libfuzzer-20-dev libllvm-20-ocaml-dev  \
                    libllvm20 libllvmlibc-20-dev libmlir-20-dev libomp-20-dev         \
                    libpolly-20-dev libunwind-20-dev lld-20 lldb-20 llvm-20           \
                    llvm-20-dev llvm-20-doc llvm-20-examples llvm-20-runtime          \
                    mlir-20-tools python3-clang-20

# 设置LLVM的基础目录
llvm_base_dir="/usr/lib/llvm-20/bin"

# 使用update-alternatives配置多个版本
tools=(
    clang
    clang++
    clangd
    clang-tidy
    clang-format
    clang-check
    clang-cpp
    lldb
    lld
    llvm-ar
    llvm-nm
    llvm-objdump
    llvm-size
)

for tool in "${tools[@]}"; do
    if [ -f "${llvm_base_dir}/${tool}-20" ]; then
        sudo update-alternatives --install /usr/bin/$tool $tool ${llvm_base_dir}/${tool}-20 100
    elif [ -f "${llvm_base_dir}/${tool}" ]; then
        sudo update-alternatives --install /usr/bin/$tool $tool ${llvm_base_dir}/${tool} 100
    else
        echo "Skipping $tool, not found in $llvm_base_dir"
    fi
done

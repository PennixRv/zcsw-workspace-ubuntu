#!/bin/bash

# 默认值设置
WITH_GCC="true"
WITH_LLVM="true"
DISABLE_SNAP="true"
WITH_ZSH="true"
CONFIG_GITHUB="true"
WITH_RUST="true"
WITH_GO="true"
WITH_ASTRONVIM="true"
WITH_VSCODE="true"

# 检查命令行参数
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 --mount-path <path-to-mount> [options]"
    exit 1
fi

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --mount-path)
            MOUNT_PATH=$(realpath "$2")
            shift 2
            ;;
        --with-gcc)
            WITH_GCC="$2"
            shift 2
            ;;
        --with-llvm)
            WITH_LLVM="$2"
            shift 2
            ;;
        --disable-snap)
            DISABLE_SNAP="$2"
            shift 2
            ;;
        --with-zsh)
            WITH_ZSH="$2"
            shift 2
            ;;
        --config-github)
            CONFIG_GITHUB="$2"
            shift 2
            ;;
        --with-rust)
            WITH_RUST="$2"
            shift 2
            ;;
        --with-go)
            WITH_GO="$2"
            shift 2
            ;;
        --with-astronvim)
            WITH_ASTRONVIM="$2"
            shift 2
            ;;
        --with-vscode)
            WITH_VSCODE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 检查挂载路径是否提供
if [ -z "${MOUNT_PATH}" ]; then
    echo "Error: Mount path must be specified with --mount-path"
    exit 1
fi

# 检查 Docker 服务状态
if ! systemctl is-active --quiet docker; then
    echo "Docker service is not running."
    read -p "Do you want to install and start Docker? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if ! sudo -v; then
            echo "Error: Current user does not have sudo privileges."
            exit 1
        fi
        sudo apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
        sudo apt --fix-broken install -y && sudo apt autoremove -y && sudo apt autoclean -y
        sudo apt-get update && sudo apt-get install -y ca-certificates curl
        sudo mkdir -p /etc/apt/keyrings && sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin && sudo apt-get install -y docker-compose
        sudo usermod -aG docker $USER
        while ! systemctl is-active --quiet docker; do sleep 5; done
    else
        echo "Docker installation aborted."
        exit 1
    fi
fi

# 获取系统的外部 IP 地址
IP=$(hostname -I | awk '{print $1}')
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export USER_NAME=$(id -un)
export GROUP_NAME=$(id -gn)
export HOME_DIR=$HOME
export HTTP_PROXY=${HTTP_PROXY}
export HTTPS_PROXY=${HTTPS_PROXY}

# 设置代理环境变量
PROXIES=("HTTP_PROXY" "HTTPS_PROXY")
for PROXY in "${PROXIES[@]}"; do
    eval VALUE=\$$PROXY
    if [[ "$VALUE" =~ ^(http|https):\/\/127\.0\.0\.1:([0-9]+)$ ]]; then
        PORT="${BASH_REMATCH[2]}"
        if [[ "$VALUE" =~ ^http:// ]]; then
            NEW_PROXY="http://$IP:$PORT"
        else
            NEW_PROXY="https://$IP:$PORT"
        fi
        export $PROXY="$NEW_PROXY"

        # 检查 Docker 环境变量，并在必要时更新
        DOCKER_PROXY=$(systemctl show --property=Environment docker | grep -o "$PROXY=[^ ]*")
        if [ "$DOCKER_PROXY" != "Environment=$PROXY=$NEW_PROXY" ]; then
            # 确保代理设置文件存在
            sudo mkdir -p /etc/systemd/system/docker.service.d
            # 更新或创建代理设置文件
            if [ ! -f /etc/systemd/system/docker.service.d/http-proxy.conf ]; then
                echo "[Service]" | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
            fi
            echo "Environment=\"$PROXY=$NEW_PROXY\"" | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
            sudo systemctl daemon-reload && sudo systemctl restart docker
        fi
    fi
done


# 创建或更新环境变量文件
cat > .env <<EOF
USER_ID=$USER_ID
GROUP_ID=$GROUP_ID
USER_NAME=$USER_NAME
GROUP_NAME=$GROUP_NAME
HOME_DIR=$HOME
MOUNT_PATH=$MOUNT_PATH
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
WITH_GCC=$WITH_GCC
WITH_LLVM=$WITH_LLVM
DISABLE_SNAP=$DISABLE_SNAP
WITH_ZSH=$WITH_ZSH
CONFIG_GITHUB=$CONFIG_GITHUB
WITH_RUST=$WITH_RUST
WITH_GO=$WITH_GO
WITH_ASTRONVIM=$WITH_ASTRONVIM
WITH_VSCODE=$WITH_VSCODE
EOF

# 使用 Docker Compose 启动服务
docker-compose up -d --build

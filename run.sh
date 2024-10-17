#!/bin/bash

WITH_GCC="true"
WITH_LLVM="true"
DISABLE_SNAP="true"
WITH_ZSH="true"
CONFIG_GITHUB="true"
WITH_RUST="true"
WITH_GO="true"
WITH_ASTRONVIM="true"
WITH_VSCODE="true"
GH_TOKEN=""
CODE_COMMITID=""
PROXY_ENABLED="false"
PROXY_CONTENT=""
IMAGE_NAME="zcsw-workspace-ubuntu"
CONTAINER_NAME="zcsw-workspace-ubuntu-container"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 --mount-path <path-to-mount> [options]"
    exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --mount-path)
            MOUNT_PATH=$(realpath "$2")
            shift 2
            ;;
        --with-gcc|--with-llvm|--with-zsh|--with-rust|--with-go|--with-astronvim|--with-vscode)
            declare "WITH_${1#--with-}"="$2"
            shift 2
            ;;
        --config-github)
            CONFIG_GITHUB="$2"
            shift 2
            ;;
        --disable-snap)
            DISABLE_SNAP="$2"
            shift 2
            ;;
        --gh-token)
            GH_TOKEN="$2"
            shift 2
            ;;
        --code-commitid)
            CODE_COMMITID="$2"
            shift 2
            ;;
        --proxy-enabled)
            PROXY_ENABLED="$2"
            shift 2
            ;;
        --proxy-content)
            PROXY_CONTENT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "${MOUNT_PATH}" ]; then
    echo "Error: Mount path must be specified with --mount-path"
    exit 1
fi

if [ "$CONFIG_GITHUB" = "true" ] && [ -z "$GH_TOKEN" ]; then
    echo "Error: GitHub token must be specified with --gh-token when GitHub configuration is enabled"
    exit 1
fi

if [ "$WITH_VSCODE" = "true" ] && [ -z "$CODE_COMMITID" ]; then
    echo "Error: VSCode commit ID must be specified with --code-commitid when VSCode installation is enabled"
    exit 1
fi

setup_deb822_sources() {
    sudo tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null <<EOT
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOT
    echo "Updated to DEB822 format sources."
}

setup_traditional_sources() {
    sudo sed -i.bak -e 's|http://archive.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
                      -e 's|http://security.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list
    echo "Updated to traditional format sources."
}

UBUNTU_VERSION=$(lsb_release -sr | grep -oP '\d+\.\d+' | head -n1)
if [ "$PROXY_ENABLED" = "false" ]; then
    read -p "Do you want to enable proxy settings (y/N)? " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        PROXY_ENABLED="true"
        default_proxy=${HTTP_PROXY:-${http_proxy:-${HTTPS_PROXY:-${https_proxy}}}}
        read -p "Enter proxy ip:port [$default_proxy]: " input_proxy
        PROXY_CONTENT="${input_proxy:-$default_proxy}"
    else
        PROXY_ENABLED="false"
        unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
        read -p "Do you want to use Tsinghua University's APT source for faster downloads in China? (y/N) " response_tuna
        if [[ "$response_tuna" =~ ^[Yy]$ ]]; then
            if [[ $(echo "$UBUNTU_VERSION >= 24.04" | bc) -eq 1 ]]; then
                setup_deb822_sources
            else
                setup_traditional_sources
            fi
            sudo apt-get update
        fi
    fi
fi
export HTTP_PROXY="${PROXY_CONTENT:-$HTTP_PROXY}"
export HTTPS_PROXY="${PROXY_CONTENT:-$HTTPS_PROXY}"

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
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
        sudo usermod -aG docker $USER
        newgrp docker
        sudo systemctl daemon-reload && sudo systemctl restart docker
        while ! systemctl is-active --quiet docker; do sleep 5; done
    else
        echo "Docker installation aborted."
        exit 1
    fi
fi

IP=$(hostname -I | awk '{print $1}')
if [ "$PROXY_ENABLED" = "true" ]; then
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
            DOCKER_PROXY=$(systemctl show --property=Environment docker | grep -o "$PROXY=[^ ]*" | cut -d '=' -f 2-)
            DESIRED_DOCKER_PROXY="$NEW_PROXY"
            if [ "$DOCKER_PROXY" != "$DESIRED_DOCKER_PROXY" ]; then
                if ! sudo -v; then
                    echo "Error: Current user does not have sudo privileges."
                    exit 1
                fi
                sudo mkdir -p /etc/systemd/system/docker.service.d
                if [ ! -f /etc/systemd/system/docker.service.d/http-proxy.conf ]; then
                    echo "[Service]" | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
                fi
                sudo sed -i "/$PROXY=/d" /etc/systemd/system/docker.service.d/http-proxy.conf
                echo "Environment=\"$PROXY=$NEW_PROXY\"" | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
                DOCKER_NEEDS_RESTART="true"
            fi
        fi
    done
fi

if [ "$PROXY_ENABLED" = "true" ]; then
    mkdir -p ~/.docker
    if [ ! -f ~/.docker/config.json ]; then
        echo '{
            "proxies": {
                "default": {
                    "httpProxy": "'$HTTP_PROXY'",
                    "httpsProxy": "'$HTTPS_PROXY'",
                    "noProxy": "localhost,127.0.0.1,.example.com"
                }
            }
        }' > ~/.docker/config.json
        DOCKER_NEEDS_RESTART="true"
    else
        sed -i 's/"httpProxy": ".*"/"httpProxy": "'$HTTP_PROXY'"/' ~/.docker/config.json
        sed -i 's/"httpsProxy": ".*"/"httpsProxy": "'$HTTPS_PROXY'"/' ~/.docker/config.json
        DOCKER_NEEDS_RESTART="true"
    fi
fi

if [ "$PROXY_ENABLED" = "false" ]; then
    read -p "Do you want to use a domestic Docker pull mirror for faster downloads in China? (y/N) " response_docker
    if [[ "$response_docker" =~ ^[Yy]$ ]]; then
        echo "Setting up domestic Docker pull mirrors..."
        sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "registry-mirrors": [
        "https://docker.1panel.dev",
        "https://docker.fxxk.dedyn.io",
        "https://docker.xn--6oq72ry9d5zx.cn",
        "https://docker.m.daocloud.io",
        "https://a.ussh.net",
        "https://docker.zhai.cm"
    ]
}
EOF
        DOCKER_NEEDS_RESTART="true"
    fi
fi

if [ "$DOCKER_NEEDS_RESTART" = "true" ]; then
    if ! sudo -v; then
        echo "Error: Current user does not have sudo privileges."
        exit 1
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

cat > .env <<EOF
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USER_NAME=$(id -un)
GROUP_NAME=$(id -gn)
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
GH_TOKEN=$GH_TOKEN
CODE_COMMITID=$CODE_COMMITID
PROXY_ENABLED=$PROXY_ENABLED
IMAGE_NAME=$IMAGE_NAME
CONTAINER_NAME=$CONTAINER_NAME
EOF

container_exists=$(docker ps -a | grep -w $CONTAINER_NAME | wc -l)
image_exists=$(docker images $IMAGE_NAME | wc -l)

if [ $container_exists -gt 0 ]; then
    echo "Container already exists. Please select an action:"
    echo "1) Delete the container and recreate it from the image"
    echo "2) Delete both the container and the image, then rebuild from scratch"
    echo "3) Skip build process and restart the container"
    echo "4) Skip build process and do nothing"

    read -p "Enter your choice (1-4): " option

    case $option in
        1)
            echo "Deleting container..."
            docker rm $CONTAINER_NAME
            echo "Creating container..."
            docker-compose build
            docker-compose up -d --progress tty
            # docker-compose up -d --build
            ;;
        2)
            echo "Deleting both container and image..."
            docker rm $CONTAINER_NAME
            docker rmi $IMAGE_NAME
            echo "Rebuilding from scratch..."
            docker-compose build --progress tty
            docker-compose up -d
            # docker-compose up -d --build
            ;;
        3)
            echo "Restarting the container..."
            docker restart $CONTAINER_NAME
            ;;
        4)
            echo "No action taken."
            ;;
        *)
            echo "Invalid option, exiting."
            exit 1
            ;;
    esac
elif [ $image_exists -gt 1 ]; then
    echo "Image exists but no container. Please select an action:"
    echo "1) Delete the image and rebuild from scratch"
    echo "2) Delete the image and all cached layers, then rebuild from scratch"
    echo "3) Build the container using the existing image"

    read -p "Enter your choice (1-3): " image_option

    case $image_option in
        1)
            echo "Deleting image..."
            docker rmi $IMAGE_NAME
            echo "Rebuilding from scratch..."
            docker-compose build --progress tty
            docker-compose up -d
            # docker-compose up -d --build
            ;;
        2)
            echo "Deleting image and all cached layers..."
            docker rmi $IMAGE_NAME
            docker system prune -a
            echo "Rebuilding from scratch..."
            docker-compose build --progress tty
            docker-compose up -d
            # docker-compose up -d --build
            ;;
        3)
            echo "Building container using existing image..."
            docker-compose build --progress tty
            docker-compose up -d
            # docker-compose up -d --build
            ;;
        *)
            echo "Invalid option, exiting."
            exit 1
            ;;
    esac
else
    echo "No existing image or container. Proceeding with build..."
    docker-compose build
    docker-compose up -d
    # docker-compose up -d --build
fi



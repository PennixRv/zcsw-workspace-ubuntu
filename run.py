import argparse
import os
import sys
from pathlib import Path
from dotenv import load_dotenv, dotenv_values, set_key

import subprocess
import sys
import socket

def is_proxy_reachable(proxy):
    # 解析代理地址和端口
    if '://' in proxy:
        proxy = proxy.split('://')[1]  # 去掉协议头
    ip, port = proxy.split(':')

    # 检查是否为回环地址
    if ip in ['localhost', '127.0.0.1']:
        # 获取本机 IP 地址
        ip = socket.gethostbyname(socket.gethostname())

    # 使用 nc (netcat) 工具检查 IP 和端口的可达性
    try:
        # 使用 subprocess.run 执行 nc 命令
        result = subprocess.run(['nc', '-zv', ip, port], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
        if result.returncode == 0:
            print(f"Proxy {ip}:{port} is reachable.")
            return f"{ip}:{port}"  # 返回可达的代理地址
        else:
            sys.exit(f"Error: Proxy {ip}:{port} is not reachable.")
    except subprocess.TimeoutExpired:
        sys.exit(f"Error: Timeout when trying to reach the proxy {ip}:{port}.")


def update_env_file(key, value):
    with open('.env', 'a') as f:
        f.write(f"{key}={value}\n")

def get_system_user_group_info():
    # 获取系统信息
    user_info = {
        'USER_ID': os.getuid(),
        'GROUP_ID': os.getgid(),
        'USER_NAME': os.getenv('USER', ''),
        'GROUP_NAME': os.getenv('GROUP', ''),
        'HOME_DIR': os.getenv('HOME', '')
    }
    
    # 更新.env文件
    for key, value in user_info.items():
        # 将每个键值对更新到.env文件，转换所有值为字符串确保正确处理
        set_key('.env', key, str(value))
    
    return user_info

def validate_user_group_args(args, env_data):
    user_args = ['user_id', 'group_id', 'user_name', 'group_name', 'home_dir']
    provided_args = [getattr(args, arg) for arg in user_args]
    
    if any(provided_args) and not all(provided_args):
        sys.exit("Error: If any of USER_ID, GROUP_ID, USER_NAME, GROUP_NAME, HOME_DIR is specified, all must be specified.")
    
    # 检查是否所有命令行参数都被提供
    if all(provided_args):
        # 更新.env文件
        for arg, value in zip(user_args, provided_args):
            set_key('.env', arg.upper(), str(value))
    else:
        # 检查.env文件
        env_values = [env_data.get(arg.upper()) for arg in user_args]
        if all(env_values):
            # 从.env文件加载
            for arg, value in zip(user_args, env_values):
                setattr(args, arg, value)
        elif any(env_values):
            sys.exit("Error: Not all user and group parameters are set in the .env file.")
        else:
            # 从系统获取并更新.env
            system_values = get_system_user_group_info()
            for arg in user_args:
                setattr(args, arg, str(system_values[arg.upper()]))

def validate_proxy_args(args, env_data):
    if args.proxy_enabled is not None:
        if args.proxy_enabled.lower() == 'true':
            if args.http_proxy or args.https_proxy:
                if not args.http_proxy:
                    args.http_proxy = args.https_proxy
                if not args.https_proxy:
                    args.https_proxy = args.http_proxy
                http_proxy = is_proxy_reachable(args.http_proxy)
                https_proxy = is_proxy_reachable(args.https_proxy)
                set_key('.env', 'HTTP_PROXY', http_proxy)
                set_key('.env', 'HTTPS_PROXY', https_proxy)
            else:
                http_proxy = os.getenv('HTTP_PROXY', '')
                https_proxy = os.getenv('HTTPS_PROXY', '')
                if http_proxy or https_proxy:
                    if not http_proxy:
                        http_proxy = https_proxy
                    if not https_proxy:
                        https_proxy = http_proxy
                    http_proxy = is_proxy_reachable(http_proxy)
                    https_proxy = is_proxy_reachable(https_proxy)
                    set_key('.env', 'HTTP_PROXY', http_proxy)
                    set_key('.env', 'HTTPS_PROXY', https_proxy)
                else:
                    sys.exit("Error: PROXY_ENABLED is true but no proxy addresses were provided or found.")
            set_key('.env', 'PROXY_ENABLED', 'true')
        elif args.proxy_enabled.lower() == 'false':
            if args.http_proxy or args.https_proxy:
                sys.exit("Error: PROXY_ENABLED is false but proxy addresses were provided.")
            set_key('.env', 'HTTP_PROXY', '')
            set_key('.env', 'HTTPS_PROXY', '')
            set_key('.env', 'PROXY_ENABLED', 'false')
    else:
        if args.http_proxy or args.https_proxy:
            if not args.http_proxy:
                args.http_proxy = args.https_proxy
            if not args.https_proxy:
                args.https_proxy = args.http_proxy
            http_proxy = is_proxy_reachable(args.http_proxy)
            https_proxy = is_proxy_reachable(args.https_proxy)
            set_key('.env', 'HTTP_PROXY', http_proxy)
            set_key('.env', 'HTTPS_PROXY', https_proxy)
        else:
            proxy_enabled = env_data.get('PROXY_ENABLED', '').lower()
            if proxy_enabled is not None:
                if proxy_enabled == 'true':
                    http_proxy = env_data.get('HTTP_PROXY', '')
                    https_proxy = env_data.get('HTTPS_PROXY', '')
                    if http_proxy or https_proxy:
                        if not http_proxy:
                            http_proxy = https_proxy
                        if not https_proxy:
                            https_proxy = http_proxy
                        http_proxy = is_proxy_reachable(http_proxy)
                        https_proxy = is_proxy_reachable(https_proxy)
                        set_key('.env', 'HTTP_PROXY', http_proxy)
                        set_key('.env', 'HTTPS_PROXY', https_proxy)
                    else:
                        http_proxy = os.getenv('HTTP_PROXY', '')
                        https_proxy = os.getenv('HTTPS_PROXY', '')
                        if http_proxy or https_proxy:
                            if not http_proxy:
                                http_proxy = https_proxy
                            if not https_proxy:
                                https_proxy = http_proxy
                            http_proxy = is_proxy_reachable(http_proxy)
                            https_proxy = is_proxy_reachable(https_proxy)
                            set_key('.env', 'HTTP_PROXY', http_proxy)
                            set_key('.env', 'HTTPS_PROXY', https_proxy)
                        else:   
                            sys.exit("Error: PROXY_ENABLED is true but no proxy addresses were provided or found.")
                elif proxy_enabled == 'false':
                    http_proxy = env_data.get('HTTP_PROXY', '')
                    https_proxy = env_data.get('HTTPS_PROXY', '')
                    if http_proxy or https_proxy:
                        sys.exit("Error: PROXY_ENABLED is false but proxy addresses were provided.")
                    else:
                        set_key('.env', 'HTTP_PROXY', '')
                        set_key('.env', 'HTTPS_PROXY', '')
                        set_key('.env', 'PROXY_ENABLED', 'false')
            else:
                http_proxy = env_data.get('HTTP_PROXY', '')
                https_proxy = env_data.get('HTTPS_PROXY', '')
                if http_proxy or https_proxy:
                    if not http_proxy:
                        http_proxy = https_proxy
                    if not https_proxy:
                        https_proxy = http_proxy
                    http_proxy = is_proxy_reachable(http_proxy)
                    https_proxy = is_proxy_reachable(https_proxy)
                    set_key('.env', 'HTTP_PROXY', http_proxy)
                    set_key('.env', 'HTTPS_PROXY', https_proxy)
                else:
                    existing_http_proxy = os.getenv('HTTP_PROXY', '')
                    existing_https_proxy = os.getenv('HTTPS_PROXY', existing_http_proxy)
                    print("No proxy settings were found. Do you want to set up a proxy now? (yes/no)")
                    response = input().strip().lower()
                    if response == 'yes':
                        proxy_input = input(f"Please enter the proxy address (IP:PORT), or leave blank to use the current setting ({existing_http_proxy or existing_https_proxy}): ").strip()
                        if not proxy_input:
                            if existing_http_proxy or existing_https_proxy:
                                if not existing_http_proxy:
                                    existing_http_proxy = existing_https_proxy
                                if not existing_https_proxy:
                                    existing_https_proxy = existing_http_proxy                                
                                http_proxy = https_proxy =existing_http_proxy
                            else:
                                print("No proxy address entered and no existing proxy settings found. No proxy will be set.")
                                set_key('.env', 'PROXY_ENABLED', 'false')
                                set_key('.env', 'HTTP_PROXY', '')
                                set_key('.env', 'HTTPS_PROXY', '')
                                return
                        else:
                            http_proxy = https_proxy = proxy_input
                        http_proxy = is_proxy_reachable(http_proxy)
                        https_proxy = is_proxy_reachable(https_proxy)
                        set_key('.env', 'HTTP_PROXY', http_proxy)
                        set_key('.env', 'HTTPS_PROXY', https_proxy)
                        set_key('.env', 'PROXY_ENABLED', 'true')

def main():
    load_dotenv('.env')
    env_data = dotenv_values('.env')
    parser = argparse.ArgumentParser(description="Run script for setting up a containerized Ubuntu workspace.")

    parser.add_argument('--mount-path', type=str, help="Path to mount inside the container.")
    parser.add_argument('--with-gcc', choices=['true', 'false'], help="Whether to include GCC.")
    parser.add_argument('--with-llvm', choices=['true', 'false'], help="Whether to include LLVM.")
    parser.add_argument('--disable-snap', choices=['true', 'false'], help="Whether to disable Snap installations.")
    parser.add_argument('--with-zsh', choices=['true', 'false'], help="Whether to include Zsh.")
    parser.add_argument('--config-github', choices=['true', 'false'], help="Whether to configure GitHub integration.")
    parser.add_argument('--with-rust', choices=['true', 'false'], help="Whether to include Rust.")
    parser.add_argument('--with-go', choices=['true', 'false'], help="Whether to include Go.")
    parser.add_argument('--with-astronvim', choices=['true', 'false'], help="Whether to include AstroNvim.")
    parser.add_argument('--with-vscode', choices=['true', 'false'], help="Whether to include VSCode.")
    parser.add_argument('--image-name', type=str, help="Docker image name.")
    parser.add_argument('--container-name', type=str, help="Docker container name.")
    parser.add_argument('--user-id', type=int, help="User ID for the container user.")
    parser.add_argument('--group-id', type=int, help="Group ID for the container user.")
    parser.add_argument('--user-name', type=str, help="User name for the container user.")
    parser.add_argument('--group-name', type=str, help="Group name for the container user.")
    parser.add_argument('--home-dir', type=str, help="Home directory for the container user.")
    parser.add_argument('--proxy-enabled', choices=['true', 'false'], help="Whether network proxy is enabled.")
    parser.add_argument('--http-proxy', type=str, help="HTTP proxy URL.")
    parser.add_argument('--https-proxy', type=str, help="HTTPS proxy URL.")
    parser.add_argument('--gh-token', type=str, help="GitHub token for configurations.")
    parser.add_argument('--code-commitid', type=str, help="VSCode commit ID required for installation.")

    args = parser.parse_args()

    # Validate and handle user and group arguments
    validate_user_group_args(args, env_data)

    # Validate and handle proxy arguments
    validate_proxy_args(args, env_data)

    # Additional processing and .env update logic goes here

if __name__ == "__main__":
    main()

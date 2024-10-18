import os
import sys
import argparse
from pathlib import Path
import subprocess
import pwd
import grp

def load_env():
    """
    从 .env 文件加载环境变量。
    返回一个字典，包含所有环境变量的键值对。
    """
    env_vars = {}
    if Path('.env').exists():
        with open('.env', 'r') as file:
            for line in file:
                key, value = line.strip().split('=', 1)
                env_vars[key] = value
    return env_vars

def save_env(env_vars):
    """
    将环境变量保存到 .env 文件。
    参数 env_vars 是包含环境变量键值对的字典。
    """
    with open('.env', 'w') as file:
        for key, value in env_vars.items():
            file.write(f'{key}={value}\n')

def parse_arguments():
    """
    解析命令行参数并返回一个包含所有参数的 argparse.Namespace 对象。
    使用 argparse 模块定义了所有预期输入的命令行参数。
    """
    parser = argparse.ArgumentParser(description="Environment Configuration Script")
    # 定义所有可能的命令行参数
    parser.add_argument('--user_id', type=int, help='User ID')
    parser.add_argument('--group_id', type=int, help='Group ID')
    parser.add_argument('--user_name', help='User name')
    parser.add_argument('--group_name', help='Group name')
    parser.add_argument('--home_dir', help='Home directory path')
    parser.add_argument('--mount_path', help='Mount path')
    parser.add_argument('--image_name', help='Docker image name')
    parser.add_argument('--container_name', help='Docker container name')
    parser.add_argument('--proxy_enabled', help='Proxy enabled (true/false)', choices=['true', 'false'])
    parser.add_argument('--http_proxy', help='HTTP proxy URL')
    parser.add_argument('--https_proxy', help='HTTPS proxy URL')
    parser.add_argument('--with_gcc', help='Include GCC', choices=['true', 'false'])
    parser.add_argument('--with_llvm', help='Include LLVM', choices=['true', 'false'])
    parser.add_argument('--disable_snap', help='Disable Snap', choices=['true', 'false'])
    parser.add_argument('--with_zsh', help='Install ZSH', choices=['true', 'false'])
    parser.add_argument('--config_github', help='Configure GitHub', choices=['true', 'false'])
    parser.add_argument('--with_rust', help='Include Rust', choices=['true', 'false'])
    parser.add_argument('--with_go', help='Include Go', choices=['true', 'false'])
    parser.add_argument('--with_astronvim', help='Install AstronVim', choices=['true', 'false'])
    parser.add_argument('--with_vscode', help='Install Visual Studio Code', choices=['true', 'false'])
    parser.add_argument('--gh_token', help='GitHub token')
    parser.add_argument('--code_commitid', help='Code commit ID')
    return parser.parse_args()

def validate_user_params(args, env_vars):
    user_params = ['user_id', 'group_id', 'user_name', 'group_name', 'home_dir']
    args_values = {param: getattr(args, param) for param in user_params}
    
    if any(args_values.values()) and not all(args_values.values()):
        print("Error: All user parameters must be set together if any are set.")
        sys.exit(1)

    if not any(args_values.values()):  # No user parameters are set via command line
        env_user_values = {param: env_vars.get(param.upper()) for param in user_params}
        if any(env_user_values.values()) and not all(env_user_values.values()):
            print("Error: Environment variables must either be all set or none at all.")
            sys.exit(1)
        elif not any(env_user_values.values()):  # No user parameters in env, fetch from system
            current_user = pwd.getpwuid(os.getuid())
            current_group = grp.getgrgid(current_user.pw_gid)
            user_info = {
                'user_id': str(current_user.pw_uid),
                'group_id': str(current_group.gr_gid),
                'user_name': current_user.pw_name,
                'group_name': current_group.gr_name,
                'home_dir': current_user.pw_dir
            }
            env_vars.update({key.upper(): value for key, value in user_info.items()})
        else:
            args_values.update(env_user_values)
    return args_values

def handle_proxies(args, env_vars):
    """
    处理代理设置逻辑，包括验证和更新env_vars。
    确保代理设置正确并且代理服务器可达。
    """
    if args.proxy_enabled:
        if args.proxy_enabled.lower() == 'true':
            if not args.http_proxy or not args.https_proxy:
                print("Both HTTP_PROXY and HTTPS_PROXY must be set if PROXY_ENABLED is true.")
                sys.exit(1)
            if not check_proxy_reachability(args.http_proxy):
                print("Error: Proxy not reachable.")
                sys.exit(1)
        elif args.proxy_enabled.lower() == 'false':
            if args.http_proxy or args.https_proxy:
                print("Error: Proxies should not be set when PROXY_ENABLED is false.")
                sys.exit(1)

        env_vars['PROXY_ENABLED'] = args.proxy_enabled
        env_vars['HTTP_PROXY'] = args.http_proxy if args.http_proxy else ''
        env_vars['HTTPS_PROXY'] = args.https_proxy if args.https_proxy else ''

def check_proxy_reachability(http_proxy):
    """
    检查HTTP代理是否可达。
    使用nc工具进行网络连接测试。
    """
    if not http_proxy:
        return False
    parts = http_proxy.split('//')[1].split(':')
    ip, port = parts[0], parts[1]
    try:
        subprocess.check_call(['nc', '-z', ip, port], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def update_environment_variables(args, env_vars):
    """
    更新环境变量基于命令行输入。
    从命令行读取的参数直接更新到环境变量中，以便将来使用。
    """
    for arg, value in vars(args).items():
        if value is not None:
            env_vars[arg.upper()] = str(value)

def main():
    args = parse_arguments()
    env_vars = load_env()
    validate_user_params(args, env_vars)
    handle_proxies(args, env_vars)
    update_environment_variables(args, env_vars)
    save_env(env_vars)
    print("Environment configuration updated successfully.")

if __name__ == "__main__":
    main()

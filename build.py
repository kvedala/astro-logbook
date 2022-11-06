import logging as log
import subprocess
import os
import yaml
from argparse import ArgumentParser, Namespace


def getBuildCount() -> int:
    output = subprocess.check_output(["git", "rev-list", "--count", "HEAD"])
    return int(output)


def makeOptions() -> Namespace:
    arg = ArgumentParser(description="Script to build the app.")
    arg.add_argument("-t", "--type", choices=['apk', 'ios', 'appbundle'],
                     type=str, default='apk',  # const='apk', nargs='?',
                     help="Type of build to make. (Default: '%(default)s')")
    arg.add_argument("--install", type=str, default=None, metavar="device",
                     help="install to 'device'. (Default: '%(default)s')")

    out = arg.parse_args()
    return out


def getVersion() -> str:
    with open("pubspec.yaml", 'r') as f:
        version = yaml.safe_load(f)
    return version['version'].split('+')[0]


if __name__ == '__main__':
    args = makeOptions()
    version = getVersion()
    # Build the project
    build = getBuildCount()
    log.info("Building:", build)
    subprocess.call(["git", "tag", f"v{version}({build})"],
                    env=os.environ.copy(), shell=True, cwd=".")
    subprocess.call(["flutter", "build", args.type, "--build-number", f"{build}"],
                    env=os.environ.copy(), shell=True, cwd=".")
    log.info("Building: Done")

    if args.install is not None:
        subprocess.call(["flutter", "install", "-d", args.install],
                        env=os.environ.copy(), shell=True, cwd=".")

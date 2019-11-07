"""
Run this to generate the templates.

.. moduleauthor:: Reece Dunham <me@rdil.rocks>
"""

import sys


def template(t):
    if t == "base":
        return {
            "builders": [
                {
                    "vm_name": "mojave-base",
                    "type": "veertu-anka",
                    "installer_app": "/Applications/Install macOS Mojave.app/",
                    "cpu_count": "2",
                    "ram_size": "8G",
                    "disk_size": "80G",
                    "boot_delay": "30s"
                }
            ],
            "provisioners": [
            ]
        }
    vmname = "mojave-xcode-{{user `xcode_version`}}"
    if t == "flutter":
        p = str(vmname)  # yeah this looks bad but we need to shallow clone it
        vmname += "-flutter"
    else:
        p = "mojave-base"

    # no need for else, it will have returned by now
    return {
        "builders": [
            {
                "vm_name": vmname,
                "source_vm_name": p,
                "type": "veertu-anka",
                "installer_app": "/Applications/Install macOS Mojave.app/",
                "cpu_count": "2",
                "ram_size": "8G",
                "disk_size": "80G",
                "boot_delay": "30s"
            }
        ],
        "provisioners": [
        ]
    }

scriptTemplate = {
    [
        {
            "inline": [
                "echo 'Disabling spotlight...'",
                "sudo mdutil -a -i off"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "yes '' | ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
            ],
            "type": "shell"
        },
        {
            "inline": [
                "echo \"export LANG=en_US.UTF-8\" >> ~/.profile",
                "echo \"export PATH=/usr/local/bin:$PATH\" >> ~/.profile",
                "echo \"export HOMEBREW_NO_AUTO_UPDATE=1\" >> ~/.profile",
                "source ~/.profile"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "brew --version",
                "brew update",
                "brew install wget cmake gcc"
            ],
            "type": "shell"
        }
    ]
}

flutterScriptTemplate = {
    [
        {
            "inline": [
                "brew cask install homebrew/cask-versions/adoptopenjdk8"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "brew cask install android-sdk android-ndk"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "echo \"export ANDROID_SDK_ROOT=/usr/local/share/android-sdk\" >> ~/.profile",
                "echo \"export ANDROID_NDK_HOME=/usr/local/share/android-ndk\" >> ~/.profile",
                "source ~/.profile"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "sdkmanager --update"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "yes | sdkmanager --licenses"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "sdkmanager tools platform-tools emulator",
                "yes | sdkmanager \"platforms;android-29\" \"build-tools;29.0.2\"",
                "echo 'export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH' >> ~/.profile"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "echo 'export FLUTTER_HOME=$HOME/flutter' >> ~/.profile",
                "echo 'export PATH=$HOME/flutter:$HOME/flutter/bin/:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH' >> ~/.profile",
                "source ~/.profile",
                "git clone https://github.com/flutter/flutter.git $FLUTTER_HOME",
                "cd $FLUTTER_HOME",
                "git checkout beta",
                "git checkout stable",
                "flutter doctor"
            ],
            "type": "shell"
        },
        {
            "inline": [
                "brew install libimobiledevice ideviceinstaller ios-deploy"
            ],
            "type": "shell"
        }
    ]
}

xcodeScriptTemplate = {
    {
        "inline": [
            "sudo gem install bundler fastlane cocoapods rake xcpretty -NV",
            "pod setup"
        ],
        "type": "shell"
    },
    {
        "environment_vars": [
            "FASTLANE_USER={{user `fastlane_user`}}",
            "FASTLANE_PASSWORD={{user `fastlane_password`}}",
            "XCODE_VERSION={{user `xcode_version`}}"
        ],
        "inline": [
            "sudo gem install xcode-install",
            "xcversion install $XCODE_VERSION",
            "xcversion select $XCODE_VERSION",
            "xcversion cleanup"
        ],
        "type": "shell"
    },
    {
        "inline": [
            "brew install xctool"
        ],
        "type": "shell"
    }
}


def add_base_meta(templateDict):
    d = templateDict.copy()
    d["provisioners"] = scriptTemplate
    return d


def add_xcode_meta(templateDict):
    di = templateDict.copy()
    di["variables"] = {
        "fastlane_user": "{{env `FASTLANE_USER`}}",
        "fastlane_password": "{{env `FASTLANE_PASSWORD`}}",
        "xcode_version": "11.1"
    }
    di["provisions"] = xcodeScriptTemplate
    return di

def add_flutter_meta(templateDict):
    dii = templateDict.copy()
    dii["variables"] = {
        "fastlane_user": "{{env `FASTLANE_USER`}}",
        "fastlane_password": "{{env `FASTLANE_PASSWORD`}}",
        "xcode_version": "11.1"
    }
    dii["provisions"] = flutterScriptTemplate
    return dii


def main():
    args = sys.argv[1:]

    if all in args:
        print(add_base_meta(template("base")))
        print(add_xcode_meta(template("xcode")))
        print(add_flutter_meta(template("flutter")))
    else:
        for u, z in enumerate(args):  # noqa
            if args[u] == "--image-variant" or args[u] == "-t":
                imagev = args[u + 1]
                print("Building image " + imagev + " metadata")
                if imagev == "base":
                    print(add_base_meta(template("base")))
                    return
                elif imagev == "flutter":
                    print(add_flutter_meta(template("flutter")))
                    return
                elif imagev == "xcode":
                    print(add_xcode_meta(template("xcode")))
                    return
                else:
                    raise ValueError("Unknown image variant " + imagev + "!")
        print("You didn't specify an image variant via `--image-variant` (or `-t`),")
        print("and didn't put `--all` (or `-a`), so I don't know what image to build!")
        raise RuntimeError("")

main()

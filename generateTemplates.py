"""
Run this to generate the templates.

.. moduleauthor:: Reece Dunham
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
    p = ""
    if t == "flutter":
        p = "mojave-xcode-{{user `xcode_version`}}"
    else:
        p = "mojave-base"
    # no need for else, it will have returned by now
    r = "mojave-xcode-{{user `xcode_version`}}-flutter"
    return {
        "builders": [
            {
                "vm_name": r,
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
    di = add_base_meta(templateDict.copy())
    di["variables"] = {
        "fastlane_user": "{{env `FASTLANE_USER`}}",
        "fastlane_password": "{{env `FASTLANE_PASSWORD`}}",
        "xcode_version": "11.1"
    }
    di["provisions"].update(xcodeScriptTemplate)
    return di


def main():
    args = sys.argv[1:]

    if all in args:
        print(add_base_meta(TEMPLATE))
        print(add_xcode_meta(TEMPLATE))
    else:
        for u, z in enumerate(args):  # noqa
            if args[u] == "--image-variant" or args[u] == "-t":
                imagev = args[u + 1]
                print("Building image " + imagev + " metadata")
                if imagev == "base":
                    print(add_base_meta(TEMPLATE))
                elif imagev == "flutter":
                    pass
                elif imagev == "xcode":
                    print(add_xcode_meta(TEMPLATE))
                else:
                    raise ValueError("Unknown image variant " + imagev + "!")
        print("You didn't specify an image variant via `--image-variant` (or `-t`),")
        print("and didn't put `--all` (or `-a`), so I don't know what image to build!")
        raise RuntimeError("")


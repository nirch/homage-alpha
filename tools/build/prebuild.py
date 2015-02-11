#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Pre build homage ios app script.
This script runs on every build of the applications.
"""

import sys
import plistlib
import base64
import time
import os
import shutil


K_SRCROOT = "srcroot"
K_TARGET_NAME = "target_name"
K_EFFECTIVE_PLATFORM_NAME = "effective_platform_name"
K_INFOPLIST_FILE = "infoplist_file"
K_CONFIGURATION = "configuration"

PODS_COPY_RESOURCES_SCRIPT = "Pods/Target Support Files/Pods/Pods-resources.sh"

HEADER = """
----------------------------------------------------------------
HOMAGE - PRE BUILD SCRIPT
By: Aviv Wolf
----------------------------------------------------------------
"""

FOOTER = """
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"""


def cfg_from_args(args):
    cfg = {
        K_SRCROOT:args[1],
        K_TARGET_NAME:args[2],
        K_EFFECTIVE_PLATFORM_NAME:args[3],
        K_INFOPLIST_FILE:args[4],
        K_CONFIGURATION:args[5]
    }
    return cfg


class Builder:
    def __init__(self, cfg):
        self.cfg = cfg
        self.is_debug = cfg[K_CONFIGURATION] == 'Debug'
        self.info = plistlib.readPlist(cfg[K_INFOPLIST_FILE])

        self.big_version = None
        self.little_version = None

        self.build_string = None
        self.build_counter = None
        self.build_version = None
        self.build_counter = None
        self.build_time = None

    def build_target(self):
        print "Build target '%s'" % self.cfg[K_TARGET_NAME]
        print "Configuration: '%s'" % self.cfg[K_CONFIGURATION]

    def parse_version(self):
        v_string = self.info['CFBundleShortVersionString'].split('.')
        self.big_version = int(v_string[0])
        self.little_version = int(v_string[1])
        print "Public version: %d.%d" % (self.big_version, self.little_version)

    def parse_build_version(self):
        print self.info

        self.build_version = [
            self.big_version,
            self.little_version,
            self.build_counter,
            self.build_time
        ]

    @staticmethod
    def base16_current_time_stamp():
        t = int(time.time())
        b16 = base64.b16encode(str(t))
        return b16


    def update_build_version(self):
        """
        Sets the build number for this build.
        The format is {BIG_VERSION_NUMBER}.{LITTLE_VERSION_NUMBER}.{BUILD_NUMBER}.{TIME_STAMP_BASE_64}
        For example: 1.8.12.1420110264
        And
        In development versions will have the .DEV suffix
        Release versions working with test servers will have the .TEST suffix
        Production versions will have no suffix

        Examples (In development, test release and production):
        1.8.12.1420110264.DEV
        1.8.12.1420110264.TEST
        1.8.12.1420110264
        """
        # Ths build counter is advanced only when compiling for Debug
        # if self.is_debug:
        #     print "Updating build count to: %d" % self.build_counter
        #     self.build_counter += 1
        # else:
        #     print "Using build count: %d" % self.build_counter
        #
        # # The build time is updated on every build
        # self.build_time = self.base16_current_time_stamp()
        #
        # self.build_version = [
        #     self.big_version,
        #     self.little_version
        # ]

    def validate_release_config(self):
        pass


    def fix_cocoapods_stupid_copy_resource_bug(self):
        # Read the cocoapods copy resource script, and make sure to correct the stupid line of code
        # they added that copies ALL xcassets resources in the project (instead of just the ones in Pods)
        src_path = self.cfg[K_SRCROOT]
        stupid_script_path = os.path.join(src_path, PODS_COPY_RESOURCES_SCRIPT)

        # Fail if script not found
        if not os.path.isfile(stupid_script_path):
            print "Missing pods copy resources file at path %s" % stupid_script_path
            exit(1)

        # Reason we are doing this: cocoapods copy resources script copies all files in xcassets
        # in the whole freak
        # Replace the stupid piece of code if found in the script with the one that only
        # copies Pods resources instead of resources of the whole project
        temp_file = "cocoapods_script_fix.tmptxt"
        shutil.copy(stupid_script_path, temp_file)
        drop_script_lines = False
        with open(temp_file, "wt") as fout:
            with open(stupid_script_path, "rt") as fin:
                for line in fin:
                    if "find . -name '*.xcassets'" in line:
                        drop_script_lines = True
                        break

                    if not drop_script_lines:
                        fout.write(line)

        # If fixes the script, copy the fixed script to it's place
        if drop_script_lines is True:
            shutil.copy(temp_file, stupid_script_path)
            print "Fixed cocoapods copy resource script at path '%s'" % (stupid_script_path)

        # Delete tmp file
        os.remove(temp_file)




if __name__ == '__main__':
    print HEADER

    # Get parameters.
    args = sys.argv
    cfg = cfg_from_args(args)

    # Bob the builder
    bob = Builder(cfg)
    bob.build_target()
    bob.parse_version()
    bob.fix_cocoapods_stupid_copy_resource_bug()
    bob.validate_release_config()
    bob.parse_build_version()
    bob.update_build_version()

    print FOOTER
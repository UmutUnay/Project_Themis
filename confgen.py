'''
Author: UMUT UNAY
Date: 2025-12-04 17:35:23
LastEditTime: 2025-12-05 17:57:14
Description: 
'''

import os
import sys

# Read the build.conf, convert each of them from CONFIG_NAME=value to #define NAME value
def conf_to_def(input_path, output_path):
    cf = open(input_path, "r")
    df = open(output_path, "w")
    df.writelines("#pragma once\n\n/*\n *\tAuto generated file, do NOT touch, or I will touch you\n */\n\n")
    for l in cf:
        if (l == '\n' or l.startswith('#')):
            continue
        [confname, value] = l.split('=')
        [tmp, name] = confname.split("CONFIG_")
        value = value.strip()
        if (value.strip() == "y"):
            value = "1"
        elif (value.strip() == "n"):
            value = "0"
        nl = "#define " + name + " " + value + "\n"
        df.writelines(nl)
    cf.close()


input_path = sys.argv[1]
output_path = sys.argv[2]
conf_to_def(input_path, output_path)
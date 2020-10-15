#!/usr/bin/env python3

import sys
import os
import csv

project_version_path = sys.argv[1]
project_version_info_path = os.path.join(project_version_path, 'defects4j-info.txt')
project_version_jaguar_output_path = os.path.join(project_version_path, 'jaguar.out')


defects4j_info_file = open(project_version_info_path, 'r')
Lines = defects4j_info_file.readlines()
root_cause = False
for line in Lines:
    line_str = line.strip()
    if root_cause:
        if line_str.startswith('---'):
            root_cause = False
        else:
            if line_str.startswith('- '):
                print(line_str)
    if line_str.startswith('Root cause in triggering tests:'):
        root_cause = True

jaguar_output_file = open(project_version_jaguar_output_path, 'r')
Lines = jaguar_output_file.readlines()
jaguar_df_test = False
for line in Lines:
    line_str = line.strip()
    #print(line_str)
    if jaguar_df_test:
        if line_str.endswith('aguar-DF has finished!'):
            jaguar_df_test = False
        else:
            print(line_str)
    if line_str.endswith('INFO]'):
        jaguar_df_test = True

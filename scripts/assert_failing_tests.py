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
defects4j_failing_tests = []
for line in Lines:
    line_str = line.strip()
    if root_cause:
        if line_str.startswith('---'):
            root_cause = False
        else:
            if line_str.startswith('- '):
                #print(line_str)
                defects4j_failing_tests.append(line_str)
    if line_str.startswith('Root cause in triggering tests:'):
        root_cause = True

jaguar_output_file = open(project_version_jaguar_output_path, 'r')
Lines = jaguar_output_file.readlines()
jaguar_failing_tests = []
for line in Lines:
    line_str = line.strip()
    if 'JaguarDF - Test' in line_str:
        #print(line_str)
        jaguar_failing_tests.append(line_str)

fieldnames = ['project_name', 'project_version', 'jaguar_failing_tests', 'defects4j_failing_tests']
writemode = 'a' if os.path.exists(os.path.join(os.getcwd(), "assert_tests.csv")) else 'w'
path_split = project_version_path.split("/")
project_name = path_split[len(path_split)-2]
project_version = path_split[len(path_split)-1]

with open('assert_tests.csv', mode=writemode) as coverage_file:
    csv_writer = csv.DictWriter(coverage_file, fieldnames=fieldnames)
    if writemode == 'w': csv_writer.writeheader()
    csv_writer.writerow({
        'project_name':project_name,
		'project_version':project_version,
		'jaguar_failing_tests':jaguar_failing_tests,
		'defects4j_failing_tests':defects4j_failing_tests
	}
)
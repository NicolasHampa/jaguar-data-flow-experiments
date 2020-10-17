#!/usr/bin/env python3

import sys
import os
import csv
from pathlib import Path

project_version_path = sys.argv[1]
defects4j_info_file_path = os.path.join(project_version_path, 'defects4j-info.txt')
jaguar_output_file_path = os.path.join(project_version_path, 'jaguar.out')
project_report_path = os.path.join(Path(project_version_path).parent.parent.parent, "reports", 'assert_tests.csv')

defects4j_info_file = open(defects4j_info_file_path, 'r')
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
                line_str_array = line_str.split('.')
                defects4j_failing_tests.append(line_str_array[-1])
    if line_str.startswith('Root cause in triggering tests:'):
        root_cause = True

jaguar_output_file = open(jaguar_output_file_path, 'r')
Lines = jaguar_output_file.readlines()
jaguar_failing_tests = []
for line in Lines:
    line_str = line.strip()
    if 'JaguarDF - Test' in line_str:
        line_str_array = line_str.split('JaguarDF - Test')
        line_str_array = (line_str_array[1]).split(':')
        class_name = (line_str_array[0]).split('.')[-1].strip()[:-1]
        test_name = (line_str_array[0]).split('(')[0].strip()
        failing_test = class_name + '::' + test_name
        jaguar_failing_tests.append(failing_test)

jaguar_failing_tests.sort()
defects4j_failing_tests.sort()
same_failing_tests = jaguar_failing_tests == defects4j_failing_tests

fieldnames = ['PROJECT_NAME', 'PROJECT_VERSION', 'SAME_FAILING_TESTS',  'JAGUAR_FAILING_TESTS', 'DEFECTS4J_FAILING_TESTS']
writemode = 'a' if os.path.exists(project_report_path) else 'w'
path_split = project_version_path.split("/")
project_name = path_split[len(path_split)-2]
project_version = path_split[len(path_split)-1]

with open(project_report_path, mode=writemode) as coverage_file:
    csv_writer = csv.DictWriter(coverage_file, fieldnames=fieldnames)
    if writemode == 'w': csv_writer.writeheader()
    csv_writer.writerow({
        'PROJECT_NAME':project_name,
		'PROJECT_VERSION':project_version,
        'SAME_FAILING_TESTS':same_failing_tests,
		'JAGUAR_FAILING_TESTS':jaguar_failing_tests,
		'DEFECTS4J_FAILING_TESTS':defects4j_failing_tests
	}
)
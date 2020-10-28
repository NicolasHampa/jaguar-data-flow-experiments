#!/usr/bin/env python3

import sys
import os
import csv
from pathlib import Path

def get_project_name(project_version_path):
    path_split = project_version_path.split("/")
    project_name = path_split[len(path_split)-2]
    return project_name

def get_project_version(project_version_path):
    path_split = project_version_path.split("/")
    project_version = path_split[len(path_split)-1]
    return project_version

def populate_defects4j_failing_tests_vector(defects4j_info_file_path):
    defects4j_failing_tests = []
    defects4j_info_file = open(defects4j_info_file_path, 'r')
    Lines = defects4j_info_file.readlines()
    root_cause = False
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
    return defects4j_failing_tests

def populate_jaguar_failling_tests_vector(jaguar_output_file_path):
    jaguar_failing_tests = []
    jaguar_output_file = open(jaguar_output_file_path, 'r')
    Lines = jaguar_output_file.readlines()
    for line in Lines:
        line_str = line.strip()
        if 'JaguarDF - Test' in line_str:
            line_str_array = line_str.split('JaguarDF - Test')
            line_str_array = (line_str_array[1]).split(':')
            class_name = (line_str_array[0]).split('.')[-1].strip()[:-1]
            test_name = (line_str_array[0]).split('(')[0].strip()
            failing_test = class_name + '::' + test_name
            jaguar_failing_tests.append(failing_test)
    return jaguar_failing_tests

def write_csv(project_report_path, project_name, project_version, same_failing_tests, jaguar_failing_tests, defects4j_failing_tests):
    writemode = 'a' if os.path.exists(project_report_path) else 'w'
    fieldnames = ['PROJECT_NAME', 'PROJECT_VERSION', 'SAME_FAILING_TESTS',  'JAGUAR_FAILING_TESTS', 'DEFECTS4J_FAILING_TESTS']
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
	
if __name__ == '__main__':
    project_version_path = sys.argv[1]
    project_name = get_project_name(project_version_path)
    project_version = get_project_version(project_version_path)

    defects4j_info_file_path = os.path.join(project_version_path, 'defects4j-info.txt')
    defects4j_failing_tests = populate_defects4j_failing_tests_vector(defects4j_info_file_path)
    defects4j_failing_tests.sort()

    jaguar_output_file_path = os.path.join(project_version_path, 'jaguar.out')
    jaguar_failing_tests = populate_jaguar_failling_tests_vector(jaguar_output_file_path)
    jaguar_failing_tests.sort()
    
    same_failing_tests = jaguar_failing_tests == defects4j_failing_tests

    project_report_path = os.path.join(Path(project_version_path).parent.parent.parent, "reports", 'assert_tests.csv')
    write_csv(project_report_path, project_name, project_version, same_failing_tests, jaguar_failing_tests, defects4j_failing_tests)
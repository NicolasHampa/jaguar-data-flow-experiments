#!/usr/bin/env python3

import numpy as np
import os
import sys
import xml.etree.ElementTree as ET
import csv
from pathlib import Path

def get_project_name(project_version_jaguar_path):
	path_split = project_version_jaguar_path.split("/")
	project_name = path_split[len(path_split)-3]
	return project_name

def get_project_version(project_version_jaguar_path):
	path_split = project_version_jaguar_path.split("/")
	project_version = path_split[len(path_split)-2]
	return project_version

def line_to_array(line):
	line = line[:-2].split()
	a = np.array(list(map(lambda x: int(x), line)))
	return a

def count_jaguar_covered_duas(jaguar_matrix_folder_path, matrix_file_name):
	total = None
	with open(os.path.join(jaguar_matrix_folder_path, matrix_file_name), "r") as matrix_file:
		for line in matrix_file:
			if line.startswith("=0"): continue
			a = line_to_array(line)
			if total is None:
				total = a
			else:
				total |= a
	return total

def write_csv(project_report_path, project_name, project_version, total_duas, jaguar_covered_duas, badua_covered_duas):
	fieldnames = ['PROJECT_NAME', 'PROJECT_VERSION', 'TOTAL_DUAS', 'JAGUAR_COVERED_DUAS', 'BADUA_COVERED_DUAS', 'SAME_COVERAGE']
	writemode = 'a' if os.path.exists(project_report_path) else 'w'
	with open(project_report_path, mode=writemode) as coverage_file:
		csv_writer = csv.DictWriter(coverage_file, fieldnames=fieldnames)
		if writemode == 'w': csv_writer.writeheader()
		csv_writer.writerow({
			'PROJECT_NAME':project_name,
			'PROJECT_VERSION':project_version,
			'TOTAL_DUAS':total_duas,
			'JAGUAR_COVERED_DUAS':jaguar_covered_duas,
			'BADUA_COVERED_DUAS':badua_covered_duas,
			'SAME_COVERAGE':(badua_covered_duas == jaguar_covered_duas)
		}
	)

if __name__ == '__main__':
	project_version_jaguar_path = sys.argv[1]

	project_name = get_project_name(project_version_jaguar_path)
	project_version = get_project_version(project_version_jaguar_path)

	project_report_path = os.path.join(Path(project_version_jaguar_path).parent.parent.parent.parent, "reports", 'assert_coverage.csv')
	jaguar_matrix_folder_path = os.path.join(project_version_jaguar_path, ".jaguar", "matrix")
	badua_report_file_path = ET.parse(os.path.join(project_version_jaguar_path, "badua_report.xml"))
	badua_xml_root = badua_report_file_path.getroot()

	total_duas = 0
	jaguar_covered_duas = 0
	badua_covered_duas = 0
	for child in badua_xml_root:
		if child.tag == "class":
			counters = child.findall("counter[@type='DU']")
			badua_covered = int(counters[0].attrib["covered"])
			badua_missed = int(counters[0].attrib["missed"])

			matrix_file_name = child.attrib["name"].replace("/", ".") 
			matrix_file_name = matrix_file_name + ".matrix"
			dua_coverage_array = count_jaguar_covered_duas(jaguar_matrix_folder_path, matrix_file_name)

			if dua_coverage_array is None: 
				pass
			else:
				jaguar_covered = np.count_nonzero(dua_coverage_array)
				jaguar_missed = dua_coverage_array.size - jaguar_covered
				jaguar_covered_duas += jaguar_covered

				badua_covered_duas += badua_covered

				total_duas += dua_coverage_array.size

	if not (badua_covered_duas == jaguar_covered_duas):
		print("Ba-Dua and Jaguar have different coverage rates for %s %s" % (project_name, project_version))

	write_csv(project_report_path, project_name, project_version, total_duas, jaguar_covered_duas, badua_covered_duas)
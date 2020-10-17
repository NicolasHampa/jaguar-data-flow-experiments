#!/usr/bin/env python3

import numpy as np
import os
import progressbar
import sys
import xml.etree.ElementTree as ET
import csv
from pathlib import Path

def line_to_array(line):
	line = line[:-2].split()
	a = np.array(list(map(lambda x: int(x), line)))
	return a

if __name__ == '__main__':
	project_name = sys.argv[1]
	project_report_path = os.path.join(Path(project_name).parent.parent.parent.parent, "reports", 'assert_coverage.csv')
	matrix_folder = os.path.join(project_name, ".jaguar", "matrix")
	tree = ET.parse(os.path.join(project_name, "badua_report.xml"))
	badua_root = tree.getroot()

	total_duas = 0
	jaguar_covered_duas = 0
	badua_covered_duas = 0

	same_coverage = True
	for child in badua_root:
		if child.tag == "class":
			counters = child.findall("counter[@type='DU']")
			badua_covered = int(counters[0].attrib["covered"])
			badua_missed = int(counters[0].attrib["missed"])
			clazz = child.attrib["name"].replace("/", ".")
			total = None

			matrix_file = clazz + ".matrix"
			with open(os.path.join(matrix_folder, matrix_file), "r") as f:
				for line in f:
					if line.startswith("=0"): continue

					a = line_to_array(line)
					if total is None:
						total = a
					else:
						total |= a

			if total is None: 
				pass
			else:
				jaguar_covered = np.count_nonzero(total)
				jaguar_missed = total.size - jaguar_covered

				total_duas += total.size
				jaguar_covered_duas += jaguar_covered
				badua_covered_duas += badua_covered

				if badua_covered != jaguar_covered:
					same_coverage = False

	fieldnames = ['PROJECT_NAME', 'PROJECT_VERSION', 'TOTAL_DUAS', 'JAGUAR_COVERED_DUAS', 'BADUA_COVERED_DUAS', 'SAME_COVERAGE']
	writemode = 'a' if os.path.exists(project_report_path) else 'w'
	path_split = project_name.split("/")
	project_name = path_split[len(path_split)-3]
	project_version = path_split[len(path_split)-2]

	if not same_coverage:
		print("Ba-Dua and Jaguar have different coverage rates for %s %s" % (project_name, project_version))

	with open(project_report_path, mode=writemode) as coverage_file:
		csv_writer = csv.DictWriter(coverage_file, fieldnames=fieldnames)
		if writemode == 'w': csv_writer.writeheader()
		csv_writer.writerow({
			'PROJECT_NAME':project_name,
			'PROJECT_VERSION':project_version,
			'TOTAL_DUAS':total_duas,
			'JAGUAR_COVERED_DUAS':jaguar_covered_duas,
			'BADUA_COVERED_DUAS':badua_covered_duas,
			'SAME_COVERAGE':same_coverage
		})
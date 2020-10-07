#!/usr/bin/env python3

import numpy as np
import os
import progressbar
import sys
import xml.etree.ElementTree as ET
import csv

def line_to_array(line):
	line = line[:-2].split()
	a = np.array(list(map(lambda x: int(x), line)))
	return a

if __name__ == '__main__':
	project_name = sys.argv[1]
	#print("Analyzing %s" % project_name)

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
					print(clazz)
					print("- BA-DUA covered: %s, Jaguar covered: %s" % (badua_covered, jaguar_covered))

	if same_coverage:
		print("Ba-Dua and Jaguar have the same coverage for %s" % project_name)

	print("Total DUAs: %s, Covered DUAs By Jaguar: %s" % (total_duas, jaguar_covered_duas))

	fieldnames = ['project_name', 'project_version', 'total_duas', 'jaguar_covered_duas', 'badua_covered_duas']
	writemode = 'a' if os.path.exists(os.path.join(os.getcwd(), "assert_coverage.csv")) else 'w'
	path_split = project_name.split("/")
	project_name = path_split[len(path_split)-3]
	project_version = path_split[len(path_split)-2]


	with open('assert_coverage.csv', mode=writemode) as coverage_file:
		csv_writer = csv.DictWriter(coverage_file, fieldnames=fieldnames)
		if writemode == 'w': csv_writer.writeheader()
		csv_writer.writerow({
			'project_name':project_name,
			'project_version':project_version,
			'total_duas':total_duas,
			'jaguar_covered_duas':jaguar_covered_duas,
			'badua_covered_duas':badua_covered_duas
		})
	#coverage_writer = csv.writer(coverage_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
	#coverage_writer.writerow([project_name, total_duas, covered_duas])

	# n_files = len([name for name in os.listdir(matrix_folder)])

	# total_duas = 0
	# covered_duas = 0
	# i = 0;

	# bar = progressbar.ProgressBar(maxval=n_files)
	# bar.start()

	# for file in os.listdir(matrix_folder):
	# 	total = None

	# 	i += 1
	# 	j = 0
	# 	with open(os.path.join(matrix_folder, file), "r") as f:
	# 		for line in f:
	# 			j += 1
	# 			if line.startswith("=0"): continue

	# 			a = line_to_array(line)
	# 			if total is None:
	# 				total = a
	# 			else:
	# 				total |= a

	# 	if total is None: continue

	# 	total_duas += total.size
	# 	covered_duas += np.count_nonzero(total)
		
		# bar.update(i)

	# bar.finish()
	# print("Total files: %s" % i)
	# print("Total DUAs: %s, Covered DUAs: %s" % (total_duas, covered_duas))

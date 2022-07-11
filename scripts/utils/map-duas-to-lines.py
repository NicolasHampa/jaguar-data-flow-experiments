#!/usr/bin/python2.7

import argparse
import re

def retrieve_dua_lines(dua):
  dua_lines = dua.rsplit(':')[1].rsplit(' ')[0]
  return re.findall("\d+", dua_lines)
def dua_lines_list(classname, dua_lines):
  lines = list()
  for lineno in dua_lines:
    lines.append('{}#{}'.format(classname_to_filename(classname), lineno))
  return lines
def classname_to_filename(classname):
  if '$' in classname:
    classname = classname[:classname.find('$')]
  return classname.replace('.', '/') + '.java'
def dua_to_lines(classdua):
  classname, dua = classdua.rsplit('#', 1)
  dua_lines = retrieve_dua_lines(dua)
  return dua_lines_list(classname, dua_lines)

parser = argparse.ArgumentParser()
parser.add_argument('--class_duas_file', required=True)
parser.add_argument('--output', required=True)

args = parser.parse_args()

#
# Collect and convert all DUAs into lines
#
class_duas = open(args.class_duas_file, 'r')
all_duas = class_duas.readlines()

all_jaguar_covered_lines = list()
for dua in all_duas:
  dua_lines = dua_to_lines(dua)
  for line in dua_lines:
    if line not in all_jaguar_covered_lines:
      all_jaguar_covered_lines.append(line)

#
# Write to the output file
#
with open(args.output, 'a') as f:
  for line in all_jaguar_covered_lines:
    f.write(line + '\n')
f.close()

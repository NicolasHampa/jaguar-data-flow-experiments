#!/usr/bin/python2.7

import argparse
import csv
import re

def classname_to_filename(classname):
  if '$' in classname:
    classname = classname[:classname.find('$')]
  return classname.replace('.', '/') + '.java'
def dua_to_lines(classdua):
  classname, dua = classdua.rsplit('#', 1)
  dua = dua.rsplit(':')[1].rsplit(' ')[0]
  dua_lines = re.findall("\d+", dua)
  lines = list()
  for lineno in dua_lines:
    lines.append('{}#{}'.format(classname_to_filename(classname), lineno))
  return lines

#assert classname_to_filename('org.apache.MyClass$Inner') == 'org/apache/MyClass.java'
#assert dua_to_line('org.apache.MyClass$Inner#123') == 'org/apache/MyClass.java#123'

parser = argparse.ArgumentParser()
parser.add_argument('--dua-susps', required=True)
parser.add_argument('--output', required=True)

args = parser.parse_args()

lines_susps = dict()

#
# Collect and convert all statements into lines
#
with open(args.dua_susps) as fin:
  reader = csv.DictReader(fin)
  for row in reader:
    lines = dua_to_lines(row['Statement'])
    susps = row['Suspiciousness']
    for line in lines:
      if line in lines_susps: # TODO can the stmts file have repetitions?
        if susps > lines_susps[line]:
          lines_susps[line] = susps
      else:
        lines_susps[line] = susps
fin.close()

#
# Write the dictionary to the output file
#
with open(args.output, 'w') as f:
  writer = csv.DictWriter(f, ['Line','Suspiciousness'])
  writer.writeheader()
  for line, susps in lines_susps.items():
    writer.writerow({'Line': line, 'Suspiciousness': susps})
f.close()

# EOF

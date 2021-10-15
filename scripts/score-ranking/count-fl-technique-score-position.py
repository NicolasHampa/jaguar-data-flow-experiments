#!/usr/bin/python3.7

if __name__ == '__main__':

  import argparse
  import os
  import csv

  import numpy as np
  import pandas as pd

  parser = argparse.ArgumentParser()
  parser.add_argument('--total_position', required=True, help='number of positions to be considered')
  parser.add_argument('--reports_path', required=True, help='path containing the scores')

  args = parser.parse_args()

  total_position = args.total_position
  reports_path = args.reports_path

  fl_evaluate = pd.read_csv(os.path.join(reports_path, 'fl-evaluate.csv'), sep=",")
  score_counter = np.zeros((int(total_position),), dtype=int)

  for row in fl_evaluate.itertuples():
    #print(str(row.Index) + ' ' + row.Technique + ' ' + str(row.Position))
    if row.Position <= int(total_position):
      score_counter[row.Position-1] += 1

  with open(os.path.join(reports_path, 'fl-count.csv'), mode='w') as csv_file:
    fieldnames = ['Position', 'NumberOfTimes']
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()

    for index, number_of_times in enumerate(score_counter):
      writer.writerow({'Position':str(index+1), 'NumberOfTimes':number_of_times})

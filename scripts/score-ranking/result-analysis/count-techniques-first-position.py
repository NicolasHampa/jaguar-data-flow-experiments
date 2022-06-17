#!/usr/bin/python3.7

import csv

from pandas import DataFrame

if __name__ == '__main__':

  import argparse
  import os

  import pandas as pd

  parser = argparse.ArgumentParser()
  parser.add_argument('--reports_path', required=True, help='root reports path containing the unified scores')
  parser.add_argument('--scores_filename', required=True, help='csv scores unified filename')
  parser.add_argument('--output', required=True, help='csv output filename')

  args = parser.parse_args()

  reports_path = args.reports_path
  scores_filename = args.scores_filename
  output = args.output

  with open(os.path.join(reports_path, output + '.csv'), mode='w') as csv_file:
    fieldnames = ['Technique', 'FirstPosition']
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()
    scores_sorted = DataFrame()
    sbfl,mlfl,sbfl_dua,mlfl_dua = 0, 0, 0, 0
    
    for root, dirs, files in os.walk(reports_path):
      if root[len(reports_path):].count(os.sep) == 1:
        # reading the csv file
        scores_sorted = pd.read_csv(os.path.join(root, scores_filename + '.csv'), sep=",")
        best_ranked = scores_sorted.iloc[:1]['Family'].values[0]
        
        if best_ranked == 'sbfl':
          sbfl = sbfl + 1
        elif  best_ranked == 'sbfl-dua':
          sbfl_dua = sbfl_dua + 1
        elif best_ranked == 'mlfl':
          mlfl = mlfl + 1
        elif best_ranked == 'mlfl-dua':
          mlfl_dua = mlfl_dua + 1
        
      if root[len(reports_path):].count(os.sep) > 2:
        continue
      
    writer.writerow({'Technique':'sbfl', 'FirstPosition':sbfl})
    writer.writerow({'Technique':'sbfl-dua', 'FirstPosition':sbfl_dua})
    writer.writerow({'Technique':'mlfl', 'FirstPosition':mlfl})
    writer.writerow({'Technique':'mlfl-dua', 'FirstPosition':mlfl_dua})      

#!/usr/bin/python3.7

from pandas import DataFrame

if __name__ == '__main__':

  import argparse
  import os

  import pandas as pd

  parser = argparse.ArgumentParser()
  parser.add_argument('--gzoltar_reports_path', required=True, help='full path for gzoltar reports folder')
  parser.add_argument('--jaguar_reports_folder', required=True, help='name of jaguar reports folder')
  parser.add_argument('--output', required=True, help='csv output filename')

  args = parser.parse_args()

  gzoltar_reports_path = args.gzoltar_reports_path
  jaguar_reports_folder = args.jaguar_reports_folder
  output = args.output
  
  df_gzoltar_scores_sorted = DataFrame()
  for root, dirs, files in os.walk(gzoltar_reports_path):
    if root[len(gzoltar_reports_path):].count(os.sep) == 2:
      jaguar_root = str(root).rsplit('/')
      jaguar_root[-3]=jaguar_reports_folder
      df_gzoltar_scores_sorted = pd.read_csv(os.path.join(root, 'scores-sorted.csv'), sep=",")
      df_jaguar_scores_sorted = pd.read_csv(os.path.join('/'.join(jaguar_root), 'scores-sorted.csv'), sep=",")
      df_unified_scores = pd.concat([df_gzoltar_scores_sorted, df_jaguar_scores_sorted])
      df_unified_scores_sorted = df_unified_scores.sort_values(by=['Score'], ascending=True)
      df_unified_scores_sorted.to_csv(str(root) + '/' + output + '.csv', sep=',', index=False)

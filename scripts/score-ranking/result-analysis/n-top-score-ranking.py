#!/usr/bin/python3.7

import sys

from pandas import DataFrame

if __name__ == '__main__':

  import argparse
  import os

  import pandas as pd

  parser = argparse.ArgumentParser()
  parser.add_argument('--reports_path', required=True, help='path containing the scores')
  parser.add_argument('--n_top', required=True, help='Number of positions to be considered')

  args = parser.parse_args()

  reports_path = args.reports_path
  n_top = args.n_top

  scores_sorted = DataFrame()
  total_versions = 0
  total_versions_on_n_top = 0
  filename = reports_path + "n_top_%s.txt" % str(n_top)
  with open(filename, 'w') as f:
    sys.stdout = f
    print('Project,Bug,Family,RankPosition,IsOnTop')
    for root, dirs, files in os.walk(reports_path):
      if root[len(reports_path):].count(os.sep) == 1:
        total_versions += 1
        scores_sorted = pd.read_csv(os.path.join(root, 'scores-sorted.csv'), sep=",")
        project = scores_sorted.iloc[:1]['Project'].values[0]
        bug = scores_sorted.iloc[:1]['Bug'].values[0]
        family = scores_sorted.iloc[:1]['Family'].values[0]
        rank_position = scores_sorted.iloc[:1]['RankPosition'].values[0]
        is_n_top = int(rank_position) <= int(n_top)
        if (is_n_top):
          total_versions_on_n_top += 1
        print(str(project) + "," + str(bug) + "," + str(family) + "," + str(rank_position) + "," + str(is_n_top))
  
    print('\nTotalVersions,TotalVersionsOnTop')
    print(str(total_versions) + "," + str(total_versions_on_n_top))

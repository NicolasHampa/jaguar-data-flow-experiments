#!/usr/bin/python3.7

import sys

from pandas import DataFrame

if __name__ == '__main__':

  import argparse
  import os

  import pandas as pd
  
  N_BUGS_EXCLUDED = {
    'Chart':[8, 10, 12, 17, 20, 23, 24],
    'Lang':[11, 13, 23, 25, 26, 29, 32, 56, 57, 62],
    'Math':[2, 3, 9, 12, 13, 17, 20, 22, 27, 30, 34, 35, 36, 45, 53, 55, 58, 60, 67, 70, 75, 89, 95, 103, 104, 105],
    'Mockito':[1, 2, 4, 5, 6, 8, 9, 11, 12, 15, 16, 26, 27, 29, 31, 33, 35, 36, 38],
    'Time':[7, 22],
    'Closure':[],
    'Cli':[3, 4, 9, 10, 26, 28, 33, 34],
    'Csv':[4, 5, 7, 10, 11, 12, 16],
    'Gson':[8, 10, 14, 16, 18],
    'Codec':[4, 7, 10, 12, 13, 16, 17],
    'JacksonCore':[13, 20, 23],
    'Compress':[13, 25, 34, 44],
    'JxPath':[14, 21],
    'JacksonDatabind':[2, 7, 21, 23, 29, 39, 40, 41, 44, 46, 49, 72, 84, 86, 99, 106, 108],
    'JacksonXml':[5, 6],
    'Jsoup':[8, 9, 13, 17, 25, 26, 31, 32, 37, 40, 44, 64, 74, 79, 85, 88]
  }

  # 'Cli':40, 'Closure':133, 'Codec':18, 'Compress':47, 'Csv':16, 'Gson':18, 'JacksonCore':26, 'JxPath':22, 'Lang':65, 'Math':106, 'Time':27

  parser = argparse.ArgumentParser()
  parser.add_argument('--reports_path', required=True, help='path containing the scores')
  parser.add_argument('--n_top', required=True, help='Number of positions to be considered')
  parser.add_argument('--ignore_uncovered', action='store_true', help='Ignore D4J versions with bug lines uncovered by Jaguar')

  args = parser.parse_args()

  reports_path = args.reports_path
  n_top = args.n_top
  ignore_uncovered=args.ignore_uncovered

  scores_sorted = DataFrame()
  total_versions = 0
  total_versions_on_n_top = 0
  filename = reports_path + "n_top_%s.txt" % str(n_top)
  with open(filename, 'w') as f:
    sys.stdout = f
    print('Project,Bug,Family,RankPosition,IsOnTop')
    for root, dirs, files in os.walk(reports_path):
      if root[len(reports_path):].count(os.sep) == 1:
        scores_sorted = pd.read_csv(os.path.join(root, 'scores-sorted.csv'), sep=",")
        project = scores_sorted.iloc[:1]['Project'].values[0]
        bug = scores_sorted.iloc[:1]['Bug'].values[0]
        family = scores_sorted.iloc[:1]['Family'].values[0]
        rank_position = scores_sorted.iloc[:1]['RankPosition'].values[0]
        
        if (ignore_uncovered and bug in N_BUGS_EXCLUDED[project]):
          continue
        
        total_versions += 1
        is_n_top = int(rank_position) <= int(n_top)
        
        if (is_n_top):
          total_versions_on_n_top += 1
        print(str(project) + "," + str(bug) + "," + str(family) + "," + str(rank_position) + "," + str(is_n_top))
  
    print('\nTotalVersions,TotalVersionsOnTop')
    print(str(total_versions) + "," + str(total_versions_on_n_top))

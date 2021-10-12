#!/usr/bin/python3.7

if __name__ == '__main__':

  import argparse
  import os
  import csv

  import pandas as pd

  parser = argparse.ArgumentParser()
  parser.add_argument('--family', required=True, help='fault localiation family to be analyzed')
  parser.add_argument('--reports_path', required=True, help='file enumerating names for matrix columns')

  args = parser.parse_args()

  reports_path = args.reports_path
  family = args.family

  with open(os.path.join(reports_path, 'fl-evaluate.csv'), mode='w') as csv_file:
    fieldnames = ['Project', 'Family', 'Position']
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()

    for root, dirs, files in os.walk(reports_path):
      if root[len(reports_path):].count(os.sep) == 2:
        df_scores_sorted = pd.read_csv(os.path.join(root, 'scores-sorted.csv'), sep=",")
        #row = df_scores_sorted.loc[df_scores_sorted['Family'] == family].iloc[0]

        for index, row in df_scores_sorted.iterrows():
          if row['Family'] == family:
            writer.writerow({'Project':root, 'Family':family, 'Position': str(index+1)})
        
      if root[len(reports_path):].count(os.sep) > 2:
        continue

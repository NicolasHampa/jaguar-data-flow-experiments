#!/usr/bin/python2.7
'''Reads paths to score-files produced by the pipeline, builds a CSV.

Run as

    python gather-scores-int-csv.py \\
      --project {Chart,Lang,...} --bug {1,2,...} \\
      --test-suite {developer,evosuite,randoop,user}

reads on standard input a bunch of paths, of the `score.txt` files produced by `do-full-analysis`, like

    my/dir/sbfl/formula-tarantula/totaldefn-tests/scoring-first/score.txt
    my/dir/mbfl/killdefn-exact/formula-ochiai/totaldefn-elements/hybrid-none/aggregator-max/scoring-last/score.txt
    ...

and writes to standard output a CSV like

    Project,Bug,TestSuite,ScoringScheme,Family,Formula,TotalDefn,KillDefn,HybridScheme,AggregationDefn,Score
    Lang,1,developer,first,sbfl,tarantula,tests,,none,,0.8
    Lang,1,developer,last,mbfl,ochiai,elements,exact,none,max,0.8
    ...

Note that the sbfl or mbfl prefix is mandatory for any given input line to this
script.
'''

import sys
import re
import csv
import os
import argparse
import logging
import pandas as pd

sbfl_path_matcher = re.compile(r'''
    (.*/|^)
    sbfl/
    formula-(?P<Formula>.*)/
    totaldefn-(?P<TotalDefn>tests|elements)/
    scoring-(?P<ScoringScheme>first|last|mean|median)/
    score.txt
  ''', re.X)
mbfl_path_matcher = re.compile(r'''
    (.*/|^)
    mbfl/
    killdefn-(?P<KillDefn>passfail|all|type|type\+message|type\+message\+location|exact)/
    formula-(?P<Formula>.*)/
    totaldefn-(?P<TotalDefn>tests|elements)/
    hybrid-(?P<HybridScheme>none|constant|mirror|numerator)/
    aggregator-(?P<AggregationDefn>max|avg)/
    scoring-(?P<ScoringScheme>first|last|mean|median)/
    score.txt
  ''', re.X)
failover_path_matcher = re.compile(r'''
    (.*/|^)
    experimental/
    (?P<Family>mbfl-coverage-only|mcbfl|failover|susp-averaging|susp-maxing|mrsbfl-failover|mrsbfl-susp-averaging|mrsbfl-susp-maxing)/
    scoring-(?P<ScoringScheme>first|last|mean|median)/
    score.txt
  ''', re.X)
mlfl_path_matcher = re.compile(r'''
    (.*/|^)
    mlfl/
    model-(?P<Formula>.*)/
    score.txt
  ''', re.X)

CSV_COLUMNS = ['Project', 'Bug', 'TestSuite', 'ScoringScheme', 'Family', 'Formula', 'TotalDefn', 'KillDefn', 'HybridScheme', 'AggregationDefn', 'Score', 'ScoreWRTLoadedClasses']
def match_to_csv_row(project, bug, test_suite, match):
  with open(match.group()) as f:
    score, score_for_loaded = f.read().strip().split(',')

  result = dict(
    Project=project, Bug=bug, TestSuite=test_suite,
    KillDefn='', AggregationDefn='', HybridScheme='none',
    Score=score, ScoreWRTLoadedClasses=score_for_loaded)
  result.update(match.groupdict())

  result.setdefault('Family',
    'sbfl' if (result['KillDefn'] == '' and result.get('ScoringScheme') != None) else
    'mlfl' if (result['KillDefn'] == '' and result.get('ScoringScheme') == None) else
    'mbfl' if result['HybridScheme'] == 'none' else
    'hybrid')
  return result

parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True, choices=['Chart', 'Closure', 'Lang', 'Math', 'Mockito', 'Time', 'ToyExample'])
parser.add_argument('--bug', required=True, type=int)
parser.add_argument('--test-suite', required=True, choices=['developer', 'evosuite', 'randoop', 'user'])
args = parser.parse_args()

logging.basicConfig(format='%(message)s',
                    level = logging.INFO,
                    filename = '/var/log/fl-score.log')

with sys.stdout as f:
  writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
  writer.writeheader()
  for line in sys.stdin:
    m = sbfl_path_matcher.match(line)
    if m is None: m = mbfl_path_matcher.match(line)
    if m is None: m = failover_path_matcher.match(line)
    if m is None: m = mlfl_path_matcher.match(line)

    if m:
      writer.writerow(match_to_csv_row(args.project, args.bug, args.test_suite, m))
    else:
      sys.stderr.write('Unable to parse line {!r}\n'.format(line))

fl_scores = pd.read_csv('../../reports/' + str(args.project) + '/' + str(args.bug) + '/scores.csv', sep=",")
sorted_scores = fl_scores.sort_values(by=['Score'], ascending=True)

sorted_scores = sorted_scores.drop(columns='TestSuite')
sorted_scores = sorted_scores.drop(columns='TotalDefn')
sorted_scores = sorted_scores.drop(columns='KillDefn')
sorted_scores = sorted_scores.drop(columns='HybridScheme')
sorted_scores = sorted_scores.drop(columns='AggregationDefn')

logging.info(format(sorted_scores.to_string()))
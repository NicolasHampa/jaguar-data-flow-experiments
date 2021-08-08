#!/usr/bin/env python3

import os
import sys
import csv

if __name__ == '__main__':
    jaguar_experiments_report_path = sys.argv[1]
    coverage_report_path = os.path.join(jaguar_experiments_report_path, 'assert_coverage.csv')
    tests_report_path = os.path.join(jaguar_experiments_report_path, 'assert_tests.csv')
    results_report_path = os.path.join(jaguar_experiments_report_path, 'assert_results.csv')

    results = []
    with open(coverage_report_path, mode='r') as coverage_file:
        csv_reader = csv.reader(coverage_file, delimiter=',')
        _ = next(csv_reader)
        csv_sorted = sorted(csv_reader, key=lambda row: (row[0], row[1]))
        line_count = 0
        for row in csv_sorted:
            project_version = row[1]
            if (project_version[-1] == 'b'):
                #print(f'\t{row[0]}, {row[1]}, {row[6]}, {row[5]}')
                results.append(f'{row[0]}, {row[1]}, {row[6]}, {row[5]}')
                line_count += 1
        print(f'Processed {line_count} lines.')

    with open(tests_report_path, mode='r') as tests_file:
        csv_reader = csv.reader(tests_file, delimiter=',')
        _ = next(csv_reader)
        csv_sorted = sorted(csv_reader, key=lambda row: (row[0], row[1]))
        line_count = 0
        for row in csv_sorted:
            #print(f'\t{row[0]}, {row[1]}, {row[2]}, {row[3]}')
            results[line_count] = results[line_count] + f', {row[2]}, {row[3]}'
            line_count += 1
        print(f'Processed {line_count} lines.')

    fieldnames = ['PROJECT_NAME', 'PROJECT_VERSION', 'SAME_FAILING_TESTS', 'JAGUAR_CONTAINS_DEFECTS4J',  'SAME_COVERAGE', 'DUA_COVERAGE_DIFFERENCE']
    with open(results_report_path, mode='w') as results_file:
        csv_writer = csv.DictWriter(results_file, fieldnames=fieldnames)
        csv_writer.writeheader()
        for row in results:
            columns = row.split(',')
            csv_writer.writerow({
                'PROJECT_NAME':columns[0],
                'PROJECT_VERSION':columns[1],
                'SAME_FAILING_TESTS':columns[4],
                'JAGUAR_CONTAINS_DEFECTS4J':columns[5],
                'SAME_COVERAGE':columns[2],
                'DUA_COVERAGE_DIFFERENCE':columns[3]
            }
    )

    print(f'Results report file successfully generated!')
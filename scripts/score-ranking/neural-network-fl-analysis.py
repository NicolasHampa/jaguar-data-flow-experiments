#!/usr/bin/python3.7

if __name__ == '__main__':

  import pandas as pd
  import numpy as np
  import argparse
  import csv

  from sklearn.neural_network import MLPClassifier

  parser = argparse.ArgumentParser()
  parser.add_argument('--matrix', required=True, help='path to the coverage/kill-matrix')
  parser.add_argument('--element-names', required=True, help='file enumerating names for matrix columns')
  parser.add_argument('--element-type', required=True, choices=['Statement', 'DUA'], help='file enumerating names for matrix columns')
  parser.add_argument('--output', required=True, help='file to write suspiciousness vector to')

  args = parser.parse_args()

  coverage_matrix = pd.read_csv(args.matrix, sep=" ", header=None)

  with open(args.element_names) as name_file:
      element_names = {i: name.strip() for i, name in enumerate(name_file)}

  total_elements = len(coverage_matrix.columns) - 1
  virtual_coverage_matrix = np.zeros((total_elements, total_elements), dtype=int)

  for element in range(total_elements):
    virtual_coverage_matrix[element][element] = 1

  test_coverage_data = coverage_matrix.iloc[:, 0:total_elements].values
  test_execution_results = coverage_matrix.iloc[:, total_elements].values

  hidden_layer_neurons=round((total_elements/30)*10)
  classifier = MLPClassifier(verbose=True,
                            max_iter=200,
                            solver='adam',
                            learning_rate_init=0.01,
                            hidden_layer_sizes=(hidden_layer_neurons,3),
                            activation='logistic')

  classifier.fit(test_coverage_data, test_execution_results)

  predictions = classifier.predict(virtual_coverage_matrix)
  predictions_proba = classifier.predict_proba(virtual_coverage_matrix)

  with open(args.output, 'w') as output_file:
      writer = csv.DictWriter(output_file, [args.element_type,'Suspiciousness'])
      writer.writeheader()
      for element in range(total_elements):
        writer.writerow({
          args.element_type: element_names[element],
          'Suspiciousness': predictions_proba[element][1]})

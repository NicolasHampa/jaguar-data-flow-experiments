#!/usr/bin/python3.8

import argparse
import torch
import csv

import pandas as pd
import numpy as np
import torch.nn as neural_network
import torch.nn.functional as function
import matplotlib.pyplot as plot

from torch.optim import Adam
from sklearn.metrics import confusion_matrix

class MultilayerPerceptron(neural_network.Module):
    def __init__(self, input_size, output_size=1):
        super(MultilayerPerceptron, self).__init__()
        hidden_layer_1=round((input_size/30)*10)
        self.fc_layer_1 = neural_network.Linear(input_size, hidden_layer_1)
        hidden_layer_2=round((hidden_layer_1/30)*10)
        self.fc_layer_2 = neural_network.Linear(hidden_layer_1, hidden_layer_2)
        hidden_layer_3=round((hidden_layer_2/30)*10)
        self.fc_layer_3 = neural_network.Linear(hidden_layer_2, hidden_layer_3)
        self.fc_layer_4 = neural_network.Linear(hidden_layer_3, output_size)
        #self.dropout = neural_network.Dropout(0.1)
        
    def forward(self, X):
        X = function.relu(self.fc_layer_1(X))
        X = function.relu(self.fc_layer_2(X))
        X = function.relu(self.fc_layer_3(X))
        #X = self.dropout(X)
        X = self.fc_layer_4(X)
        return torch.sigmoid(X)   

if __name__ == '__main__':
    torch.manual_seed(101)
    
    # Load Data    
    parser = argparse.ArgumentParser()
    parser.add_argument('--matrix', required=True, help='path to the coverage/kill-matrix')
    parser.add_argument('--element-names', required=True, help='file enumerating names for matrix columns')
    parser.add_argument('--element-type', required=True, choices=['Statement', 'DUA'], help='file enumerating names for matrix columns')
    parser.add_argument('--output', required=True, help='file to write suspiciousness vector to')

    args = parser.parse_args()
    
    # Read Coverage Data
    coverage_matrix = pd.read_csv(args.matrix, sep=" ", header=None)
    total_elements = coverage_matrix.shape[1] - 1
    
    # Training Data
    coverage_matrix.iloc[:, total_elements] = coverage_matrix.iloc[:, total_elements].replace(['+','-'],[0,1])
    test_coverage_data = torch.tensor(coverage_matrix.iloc[:, 0:total_elements].values)
    test_execution_results = torch.tensor(coverage_matrix.iloc[:, total_elements].values)

    # Testing Data
    virtual_coverage_matrix = np.zeros((total_elements, total_elements), dtype=int)
    for element in range(total_elements):
        virtual_coverage_matrix[element][element] = 1
    virtual_coverage_tensor = torch.tensor(virtual_coverage_matrix)
    
    # Prepare Model
    model = MultilayerPerceptron(total_elements)
    criterion = neural_network.MSELoss()
    optimizer = Adam(model.parameters(), lr = 0.001)
    
    epochs = 200
    train_losses = []
    train_correct = []
    
    # Run Model
    for epoch in range(epochs):
        train_corr = 0
        test_corr = 0
    
        # Train Model
        y_pred = model(test_coverage_data.float())
        loss = criterion(y_pred.squeeze(), test_execution_results.float())
            
        #predicted = torch.max(y_pred.data, 1)
        predicted = torch.round(y_pred.data).long().squeeze()
        train_corr = (predicted == test_execution_results).sum()
            
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
            
        train_losses.append(loss)
        train_correct.append(train_corr)
        
    # Test Model
    with torch.no_grad():
        y_eval=model(virtual_coverage_tensor.float())    
        predictions = y_eval.cpu().detach().numpy()
        
    # Set Calculated Suspiciousness To Each Element  
    with open(args.element_names) as name_file:
      element_names = {i: name.strip() for i, name in enumerate(name_file)}
      
    with open(args.output, 'w') as output_file:
        writer = csv.DictWriter(output_file, [args.element_type,'Suspiciousness'])
        writer.writeheader()
        for element in range(total_elements):
            writer.writerow({
                args.element_type: element_names[element],
                'Suspiciousness': float(predictions[element][0])
            })
            
    #fl_scores = pd.read_csv(args.output, sep=",")
    #sorted_scores = fl_scores.sort_values(by=['Suspiciousness'], ascending=False)
        
    # Plot results
    #plot.subplot(3, 1, 3)
    #plot.plot([t for t in train_losses], label='training loss')
    #plot.title('Training loss per epoch')
    #plot.legend()
    #plot.show()
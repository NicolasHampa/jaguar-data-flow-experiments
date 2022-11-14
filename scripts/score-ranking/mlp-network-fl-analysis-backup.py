#!/usr/bin/python3.8

import argparse
import torch
import csv

import pandas as pd
import numpy as np
import torch.nn as neural_network
import torch.nn.functional as function
import matplotlib.pyplot as plot

from pytorchtools import EarlyStopping
from torch.utils.data import DataLoader
from torch.optim import Adam
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix

class MultilayerPerceptron(neural_network.Module):
    def __init__(self, input_size, output_size=1):
        super(MultilayerPerceptron, self).__init__()
        hidden_layer_size = round((input_size/30)*10)
        self.fc_layer_1 = neural_network.Linear(input_size, hidden_layer_size)
        self.fc_layer_2 = neural_network.Linear(hidden_layer_size, hidden_layer_size)
        self.fc_layer_3 = neural_network.Linear(hidden_layer_size, hidden_layer_size)
        self.fc_layer_4 = neural_network.Linear(hidden_layer_size, output_size)
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
    
    # Parse Args    
    parser = argparse.ArgumentParser()
    parser.add_argument('--matrix', required=True, help='path to the coverage-matrix')
    parser.add_argument('--element-names', required=True, help='file enumerating names for matrix columns')
    parser.add_argument('--element-type', required=True, choices=['Statement', 'DUA'], help='file enumerating names for matrix columns')
    parser.add_argument('--output', required=True, help='file to write suspiciousness vector to')

    args = parser.parse_args()
    
    # Read Coverage Data Collected During Execution of Tests Cases
    coverage_matrix = pd.read_csv(args.matrix, sep=" ", header=None)
    total_elements = coverage_matrix.shape[1] - 1
    coverage_matrix.iloc[:, total_elements] = coverage_matrix.iloc[:, total_elements].replace(['+','-'],[0,1])

    test_coverage_data = torch.tensor(coverage_matrix.iloc[:, 0:total_elements].values)
    test_execution_results = torch.tensor(coverage_matrix.iloc[:, total_elements].values)
    
    # Max epochs to iterate
    epochs = 200
    
    # Prepare Model
    model = MultilayerPerceptron(total_elements)
    criterion = neural_network.MSELoss()
    optimizer = Adam(model.parameters(), lr = 0.001) # 0.001
    early_stopping = EarlyStopping(patience=40, delta=0.0001, verbose=True) #0.0001
    #scheduler=ReduceLROnPlateau(optimizer, mode='min', factor=0.1, patience=10, verbose=True)
    
    # to track the training loss as the model trains
    train_losses = []
        
    # Run Model
    for epoch in range(epochs):
        train_corr = 0
            
        outputs = model(test_coverage_data.float())
        loss = criterion(outputs.squeeze(), test_execution_results.float())
                
        #predicted = torch.max(y_pred.data, 1)
        predicted = torch.round(outputs.data).long().squeeze()
        train_corr = (predicted == test_execution_results).sum()
             
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
                
        train_losses.append(loss.item())
        
        # print training/validation statistics 
        # calculate average loss over an epoch
        train_loss = np.average(train_losses)
        
        epoch_len = len(str(epochs))
        
        print_msg = (f'[{epoch:>{epoch_len}}/{epochs:>{epoch_len}}] ' +
                     f'train_loss: {train_loss:.5f} ') #+
                     #f'valid_loss: {valid_loss:.5f}')
        
        print(print_msg)
        
        # clear lists to track next epoch
        train_losses = []
        
        # early_stopping needs the validation loss to check if it has decresed, 
        # and if it has, it will make a checkpoint of the current model
        early_stopping(train_loss, model)
        
        if early_stopping.early_stop:
            print("Early stopping")
            break
        
        if train_loss < 0.001:
            print("Early stopping")
            break
         
    # Build Virtual Coverage Matrix For Fault Prediction
    virtual_coverage_matrix = np.zeros((total_elements, total_elements), dtype=int)
    for element in range(total_elements):
        virtual_coverage_matrix[element][element] = 1
    virtual_coverage_tensor = torch.tensor(virtual_coverage_matrix)
        
    # Calculate Suspiciousness of Each Element 
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
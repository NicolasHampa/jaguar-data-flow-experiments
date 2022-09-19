#!/usr/bin/python3.8

import argparse
import torch

import pandas as pd
import torch.nn as neural_network
import torch.nn.functional as function
import matplotlib.pyplot as plot

from torch.utils.data import DataLoader
from torch.optim import Adam
from torchvision import datasets, transforms
from sklearn.metrics import confusion_matrix

class MultilayerPerceptron(neural_network.Module):
    def __init__(self, input_size, output_size=1, layers=[120,84]):
        super(MultilayerPerceptron, self).__init__()
        self.fc_layer_1 = neural_network.Linear(input_size, layers[0])
        self.fc_layer_2 = neural_network.Linear(layers[0], layers[1])
        self.fc_layer_3 = neural_network.Linear(layers[1], output_size)
        
    def forward(self, X):
        X = function.relu(self.fc_layer_1(X))
        X = function.relu(self.fc_layer_2(X))
        X = self.fc_layer_3(X)
        return function.sigmoid(X)   

if __name__ == '__main__':
    torch.manual_seed(101)
    
    # Load Data    
    parser = argparse.ArgumentParser()
    parser.add_argument('--matrix', required=True, help='path to the coverage/kill-matrix')
    parser.add_argument('--element-names', required=True, help='file enumerating names for matrix columns')
    parser.add_argument('--element-type', required=True, choices=['Statement', 'DUA'], help='file enumerating names for matrix columns')
    parser.add_argument('--output', required=True, help='file to write suspiciousness vector to')

    args = parser.parse_args()
    
    coverage_matrix = pd.read_csv(args.matrix, sep=" ", header=None)
    total_elements = coverage_matrix.shape[1] - 1
    
    coverage_matrix.iloc[:, total_elements] = coverage_matrix.iloc[:, total_elements].replace(['+','-'],[1,0])
    
    test_coverage_data = torch.tensor(coverage_matrix.iloc[:, 0:total_elements].values)
    test_execution_results = torch.tensor(coverage_matrix.iloc[:, total_elements].values)
    #train_data = coverage_matrix.to_numpy()

    with open(args.element_names) as name_file:
        element_names = {i: name.strip() for i, name in enumerate(name_file)}
    
    # Prepare Model
    model = MultilayerPerceptron(total_elements)
    criterion = neural_network.MSELoss()
    optimizer = Adam(model.parameters(), lr = 0.001)
    
    epochs = 10
    train_losses = []
    test_losses = []
    train_correct = []
    test_correct = []
    
    # Run Model
    for epoch in range(epochs):
        train_corr = 0
        test_corr = 0
    
        # Train Model
        #X_train_flat = X_train.view(100,-1)
        #test_coverage_data = torch.transpose(test_coverage_data, 0, 1)
        y_pred = model(test_coverage_data.float())
        loss = criterion(y_pred.squeeze(), test_execution_results.float())
            
        #predicted = torch.max(y_pred.data, 1)
        predicted = torch.round(y_pred.data).long().squeeze()
        batch_corr = (predicted == test_execution_results).sum()
        train_corr += batch_corr
            
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
            
        train_losses.append(loss)
        train_correct.append(train_corr)
        
        # Test Model
        with torch.no_grad():
            for b, (X_test, y_test) in enumerate(test_loader):
                X_test_flat = X_test.view(500,-1)
                y_eval=model(X_test_flat)
                
                predicted = torch.max(y_eval.data, 1)[1]
                test_corr += (predicted == y_test).sum()
        
            loss = criterion(y_eval, y_test)
            test_losses.append(loss)
            test_correct.append(test_corr)
    
            print('Test accuracy:', test_correct[-1].item()/10000*100)
        
    # Plot results
    plot.subplot(3, 1, 3)
    plot.plot([t/600 for t in train_correct], label='training accuracy')
    plot.plot([t/100 for t in test_correct], label='testing accuracy')
    plot.title('Accuracy per epoch')
    plot.legend()
    plot.show()
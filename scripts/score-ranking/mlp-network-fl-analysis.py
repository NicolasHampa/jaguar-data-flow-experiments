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
from torch.utils.data import SubsetRandomSampler
from torch.optim import Adam
from torch.optim.lr_scheduler import ReduceLROnPlateau
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import KFold

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

def reset_weights(m):
    '''
    Try resetting model weights to avoid
    weight leakage.
    '''
    for layer in m.children():
        if hasattr(layer, 'reset_parameters'):
            print(f'Reset trainable parameters of layer = {layer}')
            layer.reset_parameters()

if __name__ == '__main__':
    torch.manual_seed(101)
    
    # Load Data    
    parser = argparse.ArgumentParser()
    parser.add_argument('--matrix', required=True, help='path to the coverage-matrix')
    parser.add_argument('--element-names', required=True, help='file enumerating names for matrix columns')
    parser.add_argument('--element-type', required=True, choices=['Statement', 'DUA'], help='file enumerating names for matrix columns')
    parser.add_argument('--output', required=True, help='file to write suspiciousness vector to')

    args = parser.parse_args()
    
    # Read Program Coverage Data Collected During Execution of Tests Cases
    coverage_matrix = pd.read_csv(args.matrix, sep=" ", header=None)
    total_elements = coverage_matrix.shape[1] - 1
    coverage_matrix.iloc[:, total_elements] = coverage_matrix.iloc[:, total_elements].replace(['+','-'],[0,1])
    coverage_matrix_tensor = torch.tensor(coverage_matrix.values)
    #test_coverage_data = torch.tensor(coverage_matrix.iloc[:, 0:total_elements].values)
    #test_execution_results = torch.tensor(coverage_matrix.iloc[:, total_elements].values)
    
    # Define the K-fold Cross Validator
    kfold = KFold(n_splits=10, shuffle=True)
    
    # For fold results
    results = {}
    
    # Max epochs to iterate
    epochs = 200
    
    # K-fold Cross Validation model evaluation
    for fold, (train_ids, test_ids) in enumerate(kfold.split(coverage_matrix_tensor)):
        
        # Print
        print(f'FOLD {fold}')
        print('--------------------------------')
        
        # Sample elements randomly from a given list of ids, no replacement.
        train_subsampler = SubsetRandomSampler(train_ids)
        test_subsampler = SubsetRandomSampler(test_ids)
        
        # Define data loaders for training and testing data in this fold
        trainloader = DataLoader(coverage_matrix_tensor, batch_size=128, sampler=train_subsampler)
        testloader = DataLoader(coverage_matrix_tensor, batch_size=32, sampler=test_subsampler)
        
        # Prepare Model
        model = MultilayerPerceptron(total_elements)
        model.apply(reset_weights)
        criterion = neural_network.CrossEntropyLoss()
        optimizer = Adam(model.parameters(), lr = 0.001)
        early_stopping = EarlyStopping(patience=20, delta=0.01, verbose=True)
        scheduler=ReduceLROnPlateau(optimizer, mode='min', factor=0.1, patience=10, verbose=True)
        
        train_losses = []
        train_correct = []
        
        # Run Model
        for epoch in range(epochs):
            train_corr = 0
        
            # Train Model
            for b, train_batch in enumerate(trainloader):
                # Get inputs
                inputs = train_batch[:, 0:total_elements]
                targets = train_batch[:, total_elements]
                
                outputs = model(inputs.float())
                loss = criterion(outputs.squeeze(), targets.float())
                    
                #predicted = torch.max(y_pred.data, 1)
                predicted = torch.round(outputs.data).long().squeeze()
                train_corr = (predicted == targets).sum()
                    
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
                    
                train_losses.append(loss.item())
                train_correct.append(train_corr)
                
            # Calculate average loss over an epoch
            train_loss = np.average(train_losses)
            # clear lists to track next epoch
            train_losses = []
            
            epoch_len = len(str(epochs))
            print_msg = (f'[{epoch:>{epoch_len}}/{epochs:>{epoch_len}}] ' +
                        f'train_loss: {train_loss:.5f}')
            print(print_msg)
            
            # early_stopping uses the training loss to check if it has decresed
            early_stopping(train_loss, model)
            if early_stopping.early_stop:
                print("Early stopping")
                break
            
            scheduler.step(train_loss)
            
        # Process is complete.
        print('Training process has finished. Saving trained model.')

        # Print about testing
        print('Starting testing')
    
        # Saving the model
        save_path = f'./model-fold-{fold}.pth'
        torch.save(model.state_dict(), save_path)

        # Evaluationfor this fold
        correct, total = 0, 0
            
        # Test Model
        with torch.no_grad():
            # Iterate over the test data and generate predictions
            for i, test_batch in enumerate(testloader):

                # Get inputs
                inputs = test_batch[:, 0:total_elements]
                targets = test_batch[:, total_elements]

                # Generate outputs
                outputs = model(inputs.float())

                # Set total and correct
                predicted = torch.round(outputs.data).long().squeeze()
                total += targets.size(0)
                correct += (predicted == targets).sum()

            # Print accuracy
            print('Accuracy for fold %d: %d %%' % (fold, 100.0 * correct / total))
            print('--------------------------------')
            results[fold] = 100.0 * (correct / total)
            
    # Print fold results
    print(f'K-FOLD CROSS VALIDATION RESULTS')
    print('--------------------------------')
    sum = 0.0
    for key, value in results.items():
        print(f'Fold {key}: {value} %')
        sum += value
    print(f'Average: {sum/len(results.items())} %')
         
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
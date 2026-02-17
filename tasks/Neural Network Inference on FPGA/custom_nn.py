import os
os.environ["CUDA_VISIBLE_DEVICES"] = "3"
import time
import torch
import torch.nn as nn

import torchvision
import torchvision.transforms as transforms
from brevitas.nn import QuantIdentity
from brevitas.nn import QuantLinear

from common import CommonActQuant
from common import CommonWeightQuant
from tensor_norm import TensorNorm

from functools import reduce
from operator import mul

from torch.utils.data import DataLoader
import numpy as np

random_seed = 6
np.random.seed(random_seed)
torch.manual_seed(random_seed)
torch.cuda.manual_seed(random_seed)
torch.cuda.manual_seed_all(random_seed)
torch.backends.cudnn.deterministic = True
torch.backends.cudnn.benchmark = False

import matplotlib
matplotlib.use('TKAgg')
import matplotlib.pyplot as plt

import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="brevitas")
warnings.filterwarnings("ignore", category=UserWarning, module="torch._tensor")

DROPOUT = 0.2

class QuantizedMLP(nn.Module):

    def __init__(
        self,
        num_classes,
        weight_bit_width,
        act_bit_width,
        in_bit_width,
        in_channels,
        out_features,
        in_features):
        super(QuantizedMLP, self).__init__()

        self.features = nn.ModuleList()
        self.features.append(QuantIdentity(act_quant=CommonActQuant, bit_width=in_bit_width))
        self.features.append(nn.Dropout(p=DROPOUT))
        in_features = reduce(mul, in_features)
        for out_features in out_features:
            self.features.append(
                QuantLinear(
                    in_features=in_features,
                    out_features=out_features,
                    bias=False,
                    weight_bit_width=weight_bit_width,
                    weight_quant=CommonWeightQuant))
            in_features = out_features
            self.features.append(nn.BatchNorm1d(num_features=in_features))
            self.features.append(QuantIdentity(act_quant=CommonActQuant, bit_width=act_bit_width))
            self.features.append(nn.Dropout(p=DROPOUT))
        self.features.append(
            QuantLinear(
                in_features=in_features,
                out_features=num_classes,
                bias=False,
                weight_bit_width=weight_bit_width,
                weight_quant=CommonWeightQuant))
        self.features.append(TensorNorm())

        for m in self.modules():
            if isinstance(m, QuantLinear):
                torch.nn.init.uniform_(m.weight.data, -1, 1)

    def clip_weights(self, min_val, max_val):
        for mod in self.features:
            if isinstance(mod, QuantLinear):
                mod.weight.data.clamp_(min_val, max_val)

    def forward(self, x):
        x = x.view(x.shape[0], -1)
        x = 2.0 * x - torch.tensor([1.0], device=x.device)
        for mod in self.features:
            x = mod(x)
        return x

def train_model(model, criterion, optimizer, train_loader, num_epoches):
    if torch.cuda.is_available():
        print(f"GPU is used, device:{torch.cuda.get_device_name(0)}!")
        device = torch.device('cuda')
    else:
        print("CPU is used!")
        device = torch.device('cpu')
    model.to(device)
    model.train()
    loss_training = []
    acc_training = []
    start_time = time.time()

    for epoch in range(num_epoches):
        epoch_loss = 0
        correct_prediction = 0
        num_items = len(train_loader.dataset)
        for inputs, targets in train_loader:
            inputs, targets = inputs.to(device), targets.to(device)           
            optimizer.zero_grad()
            outputs = model.forward(inputs)
            loss = criterion(outputs, targets)  
            loss.backward()
            optimizer.step()
            model.clip_weights(-1, 1)
            #Calculate loss
            epoch_loss += loss.item()
            #Calculate accuracy
            __, predicts = torch.max(outputs, 1)
            correct_prediction += (predicts==targets).sum().item()

        accuracy = correct_prediction/ num_items
        average_loss = epoch_loss / len(train_loader)
        acc_training.append(accuracy)
        loss_training.append(average_loss)
        print(f"Epoch [{epoch+1}/{num_epoches}], total loss:{loss.item():.4f}, accuracy per epoch:{accuracy*100:.2f}%")

    model_save_path = "./custom_nn.pth"
    torch.save(model.state_dict(), model_save_path)
    print(f"MLP model saved to path:{model_save_path}")
    end_time = time.time()
    training_time = end_time -start_time
    print(f"Training time in total:{training_time:.2f} seconds")
    

    #plot results
    plt.figure(figsize=(10,10))
    plt.subplot(2, 1, 1)
    plt.plot(range(1, num_epoches + 1), loss_training, label='Training Loss', color='blue')
    plt.xlabel('Epoches')
    plt.ylabel('Average loss')
    plt.title(f'Training loss over {num_epoches} epoches')
    plt.legend()
    plt.subplot(2, 1, 2)
    plt.plot(range(1, num_epoches + 1), [100*acc for acc in acc_training], label='Training Accuracys', color='green')
    plt.xlabel('Epoches')
    plt.ylabel('Acurracy(%)')
    plt.title(f'Training accuracy over {num_epoches} epoches')
    plt.legend()
    plt.show()
    #plt.savefig('training_loss.png')
    return acc_training, loss_training

def load_data(batch_size=64):
    transform = transforms.Compose([
        transforms.ToTensor()
    ])
    
    train_dataset = torchvision.datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    test_dataset  = torchvision.datasets.MNIST(root='./data', train=False, download=True, transform=transform)
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader  = DataLoader(test_dataset,  batch_size=batch_size, shuffle=False)
    return train_loader, test_loader

def show_image(data_loader):
    images, labels = next(iter(data_loader))
    image = images[0]
    label = labels[0].item()
    image_np = image.reshape(28,28)
    plt.imshow(image_np, cmap='gray')
    plt.title(f'Label: {label}')
    plt.savefig('mnist_image.png')

if __name__ == "__main__":

    #Model parameters
    in_bit_width = 8
    weight_bit_width = 8
    act_bit_width = 8
    in_features = (28,28)
    out_features = [64,64,64]
    num_classes = 10
    batch_size = 100
    learning_rate = 0.0001
    num_epoches = 500

    #Model instance

    MLP = QuantizedMLP(
    weight_bit_width=weight_bit_width,
    act_bit_width=act_bit_width,
    in_bit_width=in_bit_width,
    in_channels=1,
    in_features=in_features,
    out_features=out_features,
    num_classes=num_classes
)
    #Load datasets
    train_loader, test_loader = load_data(batch_size)

    #Check test image picture with 28x28 pixel
    #show_image(test_loader)

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(MLP.parameters(), lr=learning_rate)
    print("############################")
    print("##Training the model......##")
    print("############################")
    print(f"Model architecture: {in_features}, {out_features}, {num_classes}")
    print(f"Batch size:{batch_size}")
    print(f"Number of batches:{len(train_loader)}")
    acc_training, loss_training = train_model(MLP, criterion, optimizer, train_loader, num_epoches)
    print(f"Backend used to display figures:{matplotlib.get_backend()}")

    # Test the model on test dataset after training
    print("############################")
    print("##Testing the model.......##")
    print("############################")
    correct = 0
    total = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images, labels = images.to(torch.device('cuda' if torch.cuda.is_available() else 'cpu')), labels.to(torch.device('cuda' if torch.cuda.is_available() else 'cpu'))
            outputs = MLP(images)
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    print(f'Accuracy of the network on the 10000 test images: {100 * correct // total} %')

import os
import yaml
from pprint import pprint

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader

from utils.utils import Logger, Struct
from data.megapixel_mnist.mnist_dataset import MegapixelMNIST
#from data.traffic.traffic_dataset import TrafficSigns
#from data.camelyon.camelyon_dataset import CamelyonFeatures
from architecture.ips_net import IPSNet
from training.iterative import train_one_epoch, evaluate

# Ensure the script is running from the correct directory
script_dir = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(script_dir, 'config', 'mnist_config.yml')

os.environ["CUDA_VISIBLE_DEVICES"] = "0"
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

dataset = 'mnist' # either one of {'mnist', 'camelyon', 'traffic'}

# get config
with open(config_path, "r") as ymlfile:
    c = yaml.load(ymlfile, Loader=yaml.FullLoader)
    print("Used config:"); pprint(c);
    conf = Struct(**c)

# fix the seed for reproducibility
torch.manual_seed(conf.seed)
np.random.seed(conf.seed)

# define datasets and dataloaders
if dataset == 'mnist':
    train_data = MegapixelMNIST(conf, train=True)
    test_data = MegapixelMNIST(conf, train=False)
elif dataset == 'traffic':
    train_data = TrafficSigns(conf, train=True)
    test_data = TrafficSigns(conf, train=False)
elif dataset == 'camelyon':
    train_data = CamelyonFeatures(conf, train=True)
    test_data = CamelyonFeatures(conf, train=False)

train_loader = DataLoader(train_data, batch_size=conf.B_seq // 2, shuffle=True,
    num_workers=1, pin_memory=False, persistent_workers=False)
test_loader = DataLoader(test_data, batch_size=conf.B_seq // 2, shuffle=False,
    num_workers=1, pin_memory=False, persistent_workers=False)

# define network
net = IPSNet(device, conf).to(device)

loss_nll = nn.NLLLoss()
loss_bce = nn.BCELoss()

# define optimizer, lr not important at this point
optimizer = torch.optim.AdamW(net.parameters(), lr=0, weight_decay=conf.wd)

criterions = {}
for task in conf.tasks.values():
    criterions[task['name']] = loss_nll if task['act_fn'] == 'softmax' else loss_bce

log_writer_train = Logger(conf.tasks)
log_writer_test = Logger(conf.tasks)

for epoch in range(conf.n_epoch):
    try:
        train_one_epoch(net, criterions, train_loader, optimizer, device, epoch, log_writer_train, conf)
    except Exception as e:
        print(f"Error during training epoch {epoch}: {e}")
        continue

    log_writer_train.compute_metric()

    more_to_print = {'lr': optimizer.param_groups[0]['lr']}
    log_writer_train.print_stats(epoch, train=True, **more_to_print)

    try:
        evaluate(net, criterions, test_loader, device, log_writer_test, conf)
    except Exception as e:
        print(f"Error during evaluation epoch {epoch}: {e}")
        continue
    
    log_writer_test.compute_metric()
    log_writer_test.print_stats(epoch, train=False)

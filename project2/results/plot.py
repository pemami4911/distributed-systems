import pandas as pd
import matplotlib.pyplot as plt

RESULTS_DIR='results/results0/'

# create 2 plots, one for gossip with all 4 topologies, and one for push-sum with all 4 topologies

# plot gossip
# exps = ['2D-gossip', 'imp2D-gossip', 'line-gossip', 'full-gossip']
# dfs = []
# fig = plt.figure()
# for exp in exps:
#     dfs.append(pd.read_csv(RESULTS_DIR + exp + '.txt', sep=' ', header=None, names=['nodes,time']))
#     plt.plot(dfs[-1], label=exp)

# plt.title('Gossip')
# plt.legend()
# plt.xlabel('num nodes')
# plt.ylabel('time (secs)')
# plt.show()

exps = ['2D-push-sum', 'imp2D-push-sum', 'line-push-sum', 'full-push-sum']
dfs = []
fig = plt.figure()
for exp in exps:
    dfs.append(pd.read_csv(RESULTS_DIR + exp + '.txt', sep=' ', header=None, names=['nodes,time']))
    plt.plot(dfs[-1], label=exp)

plt.title('Push-Sum')
plt.legend()
plt.xlabel('num nodes')
plt.ylabel('time (secs)')
plt.show()
```
Two Scripts are there :

1 -> common.sh
2 -> master.sh

(check ip ad and provide the right network interface always)...

I have modified both the scripts for the best k8 setup and the thing is "common.sh" is required to be run on every node which is a part of the cluster.

For "master.sh" it is only required to run on master nodes

After running these scripts the only thing you need to do is make the "workers node" join to the "master node"

use kubeadm token create --print-join-command  to get the token for worker nodes

```

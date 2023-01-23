### Example sbatch script for running containers using slurm

```
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --gpus-per-node=8
#SBATCH --ntasks-per-node=8

LOCAL_MPI="/usr/mpi/gcc/openmpi-4.1.2a1/bin"

export RX_QUEUE_LEN=8192 \
       IB_RX_QUEUE_LEN=8192 \
       UCX_TLS=tcp \
       HCOLL_ENABLE_MCAST_ALL=0 \
       coll_hcoll_enable=0 \
       UCX_NET_DEVICES=mlx5_4:1 \
       NCCL_DEBUG=WARN \
       NCCL_IB_TIMEOUT=16 \
       NCCL_IB_SL=0 \
       NCCL_IB_TC=41 \
       NCCL_IGNORE_CPU_AFFINITY=1 \
       NCCL_IB_GID_INDEX=3 \
       NCCL_IB_HCA==mlx5_0,mlx5_2,mlx5_6,mlx5_8,mlx5_10,mlx5_12,mlx5_14,mlx5_16,mlx5_1,mlx5_3,mlx5_7,mlx5_9,mlx5_11,mlx5_13,mlx5_15,mlx5_17 \
       NCCL_IB_QPS_PER_CONNECTION=4

env | grep "SLURMD_NODENAME="
env | grep "SLURM_NODELIST="

srun --gpus-per-node=8 \
     --ntasks-per-node=8 \
     --container-image="ubuntu:latest" \
     --container-mounts="$LOCAL_MPI:$LOCAL_MPI" \
     hostname
```

### If you need to build your own image and use that, then

* Use ```docker save``` to save the image to a shared location (example --> /nfs/cluster or /nfs/scratch) and then use ```docker load``` command to import that image to all nodes.

### Use the above docker image to run
1. Go to any compute node as docker is installed on all compute nodes.
2. Run ```docker image ls```. This will show the list of images and you should see your image.
3. Go to a shared directory that's shared between all nodes.
4. Run ```ENROOT_SQUASH_OPTIONS="-b 262144" enroot import dockerd://<image-name>``` (ENROOT_SQUASH_OPTIONS="-b 262144" is needed for large container sizes). A .sqsh file is created.
5. You need to have "pyxis_" before the name as the container name, as this is what is needed for slurm to work with pyxis and enroot.
```enroot create -n pyxis_<name> <full path to .sqsh file>```
6. Test on the node you are on. Make sure you pass just the "name" that you used in the previous command to --container-name and not add pyxis_ to it. When you use enroot + pyxis, slurm will automatically add that. 
Example --> ```srun -l --container-name=<name> --container-image=<path to .sqsh file> --nodelist=compute-permanent-node-1 bash -c "cat /etc/*rel*"```
7. Test on two nodes. 
Example --> ```srun -l --container-name=<name> --container-image=<path to .sqsh file> --nodelist=compute-permanent-node-[1,2] bash -c "cat /etc/*rel*"```
8. Test on all nodes. 
Example --> ```srun -l --container-name=<name> --container-image=<path to .sqsh file> --nodelist=compute-permanent-node-[1,2,3,4,5,6,7,8,9,10] bash -c "cat /etc/*rel*"```


#!/bin/bash
#SBATCH --gpus-per-node=8
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:20:00
#SBATCH --propagate=STACK

LOCAL_MPI="/opt/openmpi-4.1.3/bin"

export RX_QUEUE_LEN=8192 \
       IB_RX_QUEUE_LEN=8192 \
       UCX_TLS=tcp \
       HCOLL_ENABLE_MCAST_ALL=0 \
       coll_hcoll_enable=0 \
       UCX_NET_DEVICES=eth0 \
       NCCL_DEBUG=WARN \
       NCCL_IB_TIMEOUT=16 \
       NCCL_IB_SL=0 \
       NCCL_IB_TC=41 \
       NCCL_IGNORE_CPU_AFFINITY=1 \
       NCCL_IB_GID_INDEX=3 \
       NCCL_ALGO=Ring \
       NCCL_IB_HCA==mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_5,mlx5_6,mlx5_7,mlx5_8,mlx5_9,mlx5_10,mlx5_11,mlx5_12,mlx5_14,mlx5_15,mlx5_16,mlx5_17 \
       NCCL_TOPO_FILE=/nccl/topo.xml
       NCCL_IB_QPS_PER_CONNECTION=4

env | grep "SLURMD_NODENAME="
env | grep "SLURM_NODELIST="

srun --gpus-per-node=8 \
     --ntasks-per-node=8 \
     --container-image="nvcr.io/nvidia/pytorch:21.09-py3" \
     --container-mounts="$PWD:/nccl,$LOCAL_MPI:$LOCAL_MPI" \
     bash -c "
     source /opt/openmpi-4.1.3/bin/mpivars.sh &&
     /nccl/nccl-tests/build/all_reduce_perf -b1G -e10G -i $((1024*1024*1024*9))
     "

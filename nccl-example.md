### MPI location --> /usr/mpi/gcc/openmpi-4.1.2a1/bin/mpivars.sh

### Variables for A100-40GB
```
var_UCX_NET_DEVICES=mlx5_4:1
var_NCCL_IB_HCA="=mlx5_0,mlx5_2,mlx5_6,mlx5_8,mlx5_10,mlx5_12,mlx5_14,mlx5_16,mlx5_1,mlx5_3,mlx5_7,mlx5_9,mlx5_11,mlx5_13,mlx5_15,mlx5_17"
```

### NOTE: ```-x NCCL_ALGO=Ring``` should only be used when running the NCCL test. For your regular workloads, please don't add that parameter.

### Example nccl_run_allreduce.sbatch

```
#!/bin/bash
#SBATCH --job-name=nccl-allreduce-slurm
#SBATCH --nodes=32
#SBATCH --exclusive
export PMI_DEBUG=1

cd /nfs/scratch
mkdir $SLURM_JOB_ID
cd $SLURM_JOB_ID

MACHINEFILE="hostfile"
ORDEREDMACHINEFILE="ordered_hostfile_system_name"
ORDEREDRANKMACHINEFILE="rankfile_system_name"

scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE
echo MACHINEFILE
cat $MACHINEFILE

python3 /home/opc/node_ordering_by_rack.py --input_file $MACHINEFILE > /dev/null

echo ORDEREDMACHINEFILE
cat $ORDEREDMACHINEFILE
echo ORDEREDRANKMACHINEFILE
cat $ORDEREDRANKMACHINEFILE

source /usr/mpi/gcc/openmpi-4.1.2a1/bin/mpivars.sh

export NCCL_DEBUG=WARN

shape=`curl -sH "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq .shape`
if [ $shape == \"BM.GPU.B4.8\" ] || [ $shape == \"BM.GPU.A100-v2.8\" ]
then
  var_UCX_NET_DEVICES=mlx5_0:1
  var_NCCL_IB_HCA="=mlx5_5,mlx5_6,mlx5_7,mlx5_8,mlx5_1,mlx5_2,mlx5_3,mlx5_4,mlx5_14,mlx5_15,mlx5_16,mlx5_17,mlx5_9,mlx5_10,mlx5_11,mlx5_12"
elif [ $shape == \"BM.GPU4.8\" ]
then
  var_UCX_NET_DEVICES=mlx5_4:1
  var_NCCL_IB_HCA="=mlx5_0,mlx5_2,mlx5_6,mlx5_8,mlx5_10,mlx5_12,mlx5_14,mlx5_16,mlx5_1,mlx5_3,mlx5_7,mlx5_9,mlx5_11,mlx5_13,mlx5_15,mlx5_17"
fi

  mpirun --mca pml ucx \
  --bind-to numa \
  -x NCCL_DEBUG=WARN \
  -x NCCL_IB_SL=0 \
  -x NCCL_IB_TC=41 \
  -x NCCL_IB_QPS_PER_CONNECTION=4 \
  -x UCX_TLS=ud,self,sm \
  -x UCX_NET_DEVICES=${var_UCX_NET_DEVICES} \
  -x HCOLL_ENABLE_MCAST_ALL=0 \
  -x coll_hcoll_enable=0 \
  -x NCCL_IB_GID_INDEX=3 \
  -x NCCL_ALGO=Ring \
  -x NCCL_IB_HCA="${var_NCCL_IB_HCA}" \
  --np $((SLURM_NNODES*SLURM_NTASKS_PER_NODE))  --rankfile $ORDEREDRANKMACHINEFILE  /home/opc/nccl-tests/build/all_reduce_perf -b1G -e10G -i$((1024*1024*1024*9)) -n 100
```

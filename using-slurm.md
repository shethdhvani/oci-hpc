Below are some commands that you would need to run your job using slurm.

* sinfo --> Determine what partitions exist on the system, what nodes they include, and general system state

* squeue --> Determine what jobs exist on the system

* scontrol --> Get more detailed information about nodes, partitions, jobs, job steps, and configuration

Example: ```scontrol show partition```

* srun --> Create a resource allocation and launch the tasks for a job. Depending upon the MPI implementation used, MPI jobs may also be launched in this manner. Refer MPI for more MPI-specific information.

Example: ```srun -N3 -l /bin/hostname```

In this example we execute /bin/hostname on three nodes (-N3) and include task numbers on the output (-l). The default partition will be used. One task per node will be used by default.

* sbatch <script> --> Submit a job script for later execution. The script will typically contain one or more srun commands to launch parallel tasks.

Example script
```
#!/bin/sh
#SBATCH -N 2
#SBATCH --exclusive
#SBATCH --job-name sleep_job

cd /nfs/scratch
mkdir $SLURM_JOB_ID
cd $SLURM_JOB_ID
MACHINEFILE="hostfile"

# Generate Machinefile for mpi such that hosts are in the same
#  order as if run via srun
#
#srun -N$SLURM_NNODES -n$SLURM_NNODES  hostname  > $MACHINEFILE
scontrol show hostnames $SLURM_JOB_NODELIST > $MACHINEFILE
sed -i "s/$/:${SLURM_NTASKS_PER_NODE}/" $MACHINEFILE

cat $MACHINEFILE
# Run using generated Machine file:
sleep 30
```

To execute your job on particular nodes, use this command
  ```sbatch -w <nodelist> <script>```

To exclude certain nodes from running your job
  ```sbatch --exclude=<nodelist> <script>```

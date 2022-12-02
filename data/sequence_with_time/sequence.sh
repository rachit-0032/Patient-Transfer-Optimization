#!/bin/bash
#SBATCH --job-name=OPT_limit
#SBATCH --output=opt_limit.txt
#SBATCH --error=opt_error_limit.txt
#SBATCH --partition=sched_mit_sloan_batch
#SBATCH -N 10
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=20GB
#SBATCH --time=4-00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=rachitj@mit.edu

# srun model.sh $SLURM_ARRAY_TASK_ID

# Initialize the module command first source
# source /etc/profile

# Load Julia Module
# module load julia/1.8.2
module load gurobi/8.1.1

grbgetkey 374ce5ba-6c21-11ed-8d11-0242ac190002
export GRB_LICENSE_FILE=/home/rachitj/gurobi.lic

~/software/julia-1.8.2/bin/julia sequence.jl
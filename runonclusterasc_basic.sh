#!/bin/bash
#SBATCH --job-name=my_sim_array
#SBATCH --output=log.txt
#SBATCH --array=1-10
#SBATCH --time=01:59:59
#SBATCH --mem-per-cpu=500
#SBATCH --mail-user=<your_mail>
#SBATCH --mail-type=END

#directory containing all your stuff e.g. parameters
BASEDIR="/project/th-scratch/<your directory>"
#file containing simulation parameters
PARAMFILE="$BASEDIR/Parameters.txt"
#where to put the results
FINALDIR="$BASEDIR/SimulationResults"

#read parameters
PARAMETERS=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${PARAMFILE})

#directory containing your program
WORKDIR="$BASEDIR/Program"
#adjust this name
PROGRAMNAME="program"
PROGRAM="${WORKDIR}/${PROGRAMNAME}"


# make sure that /data/$USER/ exists
if [ ! -e /data/$USER/ ]; then
    mkdir /data/$USER/
fi

# create local directories 
if [ ! -e /data/$USER/job${SLURM_JOB_ID}/ ]; then
           mkdir -p /data/$USER/job${SLURM_JOB_ID}/
else
# case it already exists (highly unusual)
    echo "Clean up /data/$USER/ directory on $HOSTNAME"
    exit 1
fi

# create a local copy of the program and that data file and start the job
PROG=`basename $PROGRAM`

cp $PROGRAM /data/$USER/job${SLURM_JOB_ID}/$PROG

cd /data/$USER/job${SLURM_JOB_ID}



saveAndCleanUp () {
	# copy all output files back to your home directory
	# and clean up
	rm $PROG

	# copy output files of each task into job directory/taskid
	if [ ! -e $FINALDIR/job${SLURM_ARRAY_JOB_ID} ]; then
	    mkdir $FINALDIR/job${SLURM_ARRAY_JOB_ID}
	fi
	#just to make sure
	cd /data/$USER/job${SLURM_JOB_ID}

#this line needs to be adapted for your data format (now hdf5) and file names (now just one with the name results)
        cp  *.hdf5 $FINALDIR/job${SLURM_ARRAY_JOB_ID}/results_${SLURM_ARRAY_TASK_ID}.hdf5
	rm -r /data/$USER/job${SLURM_JOB_ID}
}


#start job with respective parameters
./$PROG $PARAMETERS
saveAndCleanUp

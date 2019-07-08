#!/bin/bash

#SBATCH --job-name=my_job
#SBATCH --output=log.txt
#SBATCH --array=1-6
#SBATCH --time=01:59:59
#SBATCH --mem-per-cpu=1000
#SBATCH --nodes=1-1
#SBATCH --mem-per-cpu=500
#SBATCH --mail-user=<your_mail>
#SBATCH --mail-type=END
#this sends a USR1 signal to the bash 120 seconds before the end of the job
#SBATCH --signal=B:USR1@120

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

#Catch signals send to the bash. This includes the one 120 seconds
#before the job runs out of time
terminate_job () {
	echo "Traphandler invoked on $HOSTNAME for job ${SLURM_JOB_ID}"
#Sends signal to the program itself to prepare for termination
#How this signal will be handled is up to the program.
#E.g. use <csignal> in C++ to create a handler function and secure your data
	kill -SIGTERM $!
	sleep 10
	saveAndCleanUp
	exit
}
#activate trap handler
trap terminate_job USR1

#In case a larger stack size is needed. The soft limit is increased to 16384kB
ulimit -S -s 16384

#in case special modules need to be loaded
#the new bash started wont know the same path...
source /etc/profile
#put the name of the modules here
module load <module name>

#start job with respective options and pipe output into respective files
#the job runs in the background such that the bash can catch signals
./$PROG $PARAMETERS > $FINALDIR/job${SLURM_JOB_ID}.outputs/stdout.txt 2> $FINALDIR/job${SLURM_JOB_ID}.outputs/stderr.txt &

#wait for the job to finish
wait
saveAndCleanUp

# ASC_Cluster_Scripts
Example Scripts for submitting jobs to the ASC-Cluster
These scripts are meant as a basis for new students to submit simulations to ASC-Cluster. Same parts of the scripts have
to be completed by the user. They take into account the structure of file server system and the file system of the 
individual machines to optimized performance.
Parameter sweeps are realized as job arrays. 
Simulations can be parallelized using pthreads or OpenMP on a single node or using OpenMPI on multiple nodes.
Signaling is included. Programs have to be adapted accordingly for example using <csignal>.

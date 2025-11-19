#!/bin/bash

#Script checks status of a jobid
#Example Usage: ./check_job_status.sh 4249999 [slurm|pbs]

#set -x

if [ -z "$1" ]; then
    echo "USAGE: $0 jobid [scheduler]"
    exit 1
fi

jobid="$1"
scheduler="${2:-slurm}"

if [ "$scheduler" = "slurm" ]; then
    if sacct | grep -q ${jobid}; then
        msg=$(sacct -j ${jobid} | grep -v "^[0-9]*\." | tail -n 1 | awk '{print $(NF-1)}')
        echo ${msg}
        code=$(sacct -j ${jobid} | grep -v "^[0-9]*\." | tail -n 1 | awk '{split($NF,code,":"); print code[1]}')
        exit ${code}
    fi
elif [ "$scheduler" = "pbs" ]; then
    if qstat ${jobid} > /dev/null 2>&1; then
        echo "RUNNING/PENDING"
        exit 0
    fi

    job_info=$(qstat -x -f ${jobid} 2>/dev/null)
    if [ $? -eq 0 ]; then

        exit_status=$(echo "$job_info" | grep "Exit_status" | awk '{print $3}')
        if [ -n "$exit_status" ]; then
            echo "FINISHED: Exit_status $exit_status"
            exit $exit_status
        else
            echo "FINISHED (Unknown Exit_status)"
            exit 0
        fi
    fi
else
    echo "Error: Unknown scheduler $scheduler"
    exit 1
fi

>&2 echo "Error: ${jobid} could not be found"
exit -1

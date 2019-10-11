#!/bin/bash -x

while read host osds
do
    for osd in $osds
    do
	echo "Removing OSD ${osd} from ${host}..."

	# Mark the OSD as down and rebalance data from it
        sudo ceph osd out $osd
    done
done < osd-victims.dat

sleep 60
until (sudo ceph osd pool stats --format=json | ./wait-for-rebalance.py) ; do sleep 10 ; done

while read host osds
do
    for osd in $osds
    do
	echo "Stopping OSD ${osd} from ${host}..."

	# Mark the OSD as down and rebalance data from it
        ssh -i ~/.ssh/id_euclid stelfer@${host} sudo systemctl stop ceph-osd@${osd}
    done
done < osd-victims.dat

# Precautionary rebalance, shouldn't be needed.
sleep 60
until (sudo ceph osd pool stats --format=json | ./wait-for-rebalance.py) ; do sleep 10 ; done

while read host osds
do
    for osd in $osds
    do
	echo "Purging OSD ${osd} from ${host}..."

        # Remove it from the cluster altogether and rebalance data again
        sudo ceph osd purge $osd --yes-i-really-mean-it
        sleep 60
        until (sudo ceph osd pool stats --format=json | ./wait-for-rebalance.py) ; do sleep 10 ; done
    done
done < osd-victims.dat

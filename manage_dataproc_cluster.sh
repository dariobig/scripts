#!/bin/bash
CLUSTER_NAME=dario-dev-dataproc-1
REGION=us-central1
ZONE=us-central1-a
NODES=2
PREEMPTIBLE=0
# https://cloud.google.com/compute/vm-instance-pricing
# type	cores	RAM	$/hour	$/hour preempt
# n1-standard-4	4	15GB	$0.1900	$0.0400
# n1-standard-8	8	30GB	$0.3800	$0.0800
# n1-highmem-2	2	13GB	$0.1184	$0.0250
# n1-highmem-4	4	26GB	$0.2368	$0.0500
# n1-highmem-8	8	52GB	$0.4736	$0.1000
# n2-standard-4	4	16GB	$0.1942	$0.0470
# n2-standard-8	8	32GB	$0.3885	$0.0940
# n2-highmem-4	4	32GB	$0.2620	$0.0634
# n2d-standard-4	4	16GB	$0.1690	$0.0409
# n2d-highmem-2	2	16 GB	$0.1140	$0.0276
# n2d-highmem-4	4	32 GB	$0.2280	$0.0552
# n2d-standard-8	8	32GB	$0.3380	$0.0818
WORKER=n2d-highmem-4
MASTER=n2d-highmem-2
STORAGE_BUCKET=dario-dev-us-central1
DISK_SIZE=1TB
SCRIPT_FOLDER="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_FILE=`basename "$0"`
SCRIPT_PATH="${SCRIPT_FOLDER}/${SCRIPT_FILE}"

REMOTE_SCRIPT="gs://${STORAGE_BUCKET}/scripts/${SCRIPT_FILE}"


function ScaleCluster {
    echo "Scaling secondary workers up/down to ${1} ... "
    gcloud beta dataproc clusters update $CLUSTER_NAME \
      --region $REGION \
      --num-secondary-workers=$1 \
      --graceful-decommission-timeout=10m
}

function UploadScript {
    CMD="gsutil cp ${SCRIPT_PATH} ${REMOTE_SCRIPT}"
    echo $CMD
    $CMD
}

function DownloadScript {
    echo "Continuing will overwrite ${SCRIPT_PATH} with the content of ${REMOTE_SCRIPT}"
    read -p "Do you want to continue (y/n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    CMD="gsutil cp ${REMOTE_SCRIPT} ${SCRIPT_PATH}"
    echo $CMD
    $CMD
}

function ListOperations {
    gcloud beta dataproc operations list --cluster $CLUSTER_NAME --region $REGION
}

function DescribeOperation {
    echo "Showing info for operation: $1 in region: $REGION"
    gcloud beta dataproc operations describe --region $REGION $1
}

function CancelOperation {
    echo "Canceling operation: $1 in region: $REGION"
    gcloud beta dataproc operations cancel --region $REGION $1
}

function ListMachineTypes {
    gcloud compute machine-types list --filter="zone:( ${REGION} )"
}

function CreateCluster {
    SECONDARY_NODES=$1

    gcloud beta dataproc clusters create $CLUSTER_NAME \
        --enable-component-gateway \
        --bucket $STORAGE_BUCKET \
        --region $REGION \
        --subnet default \
        --zone $ZONE \
        --master-machine-type $MASTER \
        --master-boot-disk-size $DISK_SIZE \
        --num-workers $NODES \
        --worker-machine-type $WORKER \
        --worker-boot-disk-size $DISK_SIZE \
        --num-secondary-workers $SECONDARY_NODES \
        --secondary-worker-boot-disk-size $DISK_SIZE \
        --image-version 1.5-debian10 \
        --optional-components ANACONDA,JUPYTER \
        --scopes 'https://www.googleapis.com/auth/cloud-platform' \
        --project river-cloud-209923 \
        --max-idle 8h \
        --initialization-actions gs://goog-dataproc-initialization-actions-${REGION}/python/pip-install.sh \
        --metadata 'PIP_PACKAGES=pandas pydash simhash nltk spacy tldextract plotly cufflinks'
        # --autoscaling-policy policy-preemptible-only-0-to-100
        # --initialization-actions gs://goog-dataproc-initialization-actions-${REGION}/python/conda-install.sh,gs://goog-dataproc-initialization-actions-${REGION}/python/pip-install.sh
        #  --metadata 'CONDA_PACKAGES="scipy=1.1.0 tensorflow"' \
}

function DeleteCluster {
    gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION
}

COMMAND=`echo $1 | tr '[:upper:]' '[:lower:]'`

for CREATE in 'create' 'new' 'make' 'build' 'up'; do
    if [ "$COMMAND" = "$CREATE" ]; then
        if [ -z "$2" ]; then
            SECONDARY_NODES=$PREEMPTIBLE
        else
            SECONDARY_NODES=$2
        fi

        echo "creating cluster with ${SECONDARY_NODES} pre-emptible nodes ... "
        CreateCluster $SECONDARY_NODES
        exit 0
    fi
done


for DELETE in 'delete' 'rm' 'destroy' 'del' 'down'; do
    if [ "$COMMAND" = "$DELETE" ]; then
        echo 'deleting cluster ... '
        DeleteCluster
        exit 0
    fi
done

if [ "$COMMAND" = "operations" ]; then
    ListOperations
    exit 0
fi

if [ "$COMMAND" = "operation" ]; then
    DescribeOperation "$2"
    exit 0
fi

if [ "$COMMAND" = "cancel" ]; then
    CancelOperation "$2"
    exit 0
fi

if [ "$COMMAND" = "upload" ]; then
    UploadScript
    exit 0
fi

if [ "$COMMAND" = "download" ]; then
    DownloadScript
    exit 0
fi

if [ "$COMMAND" = "types" ]; then
    ListMachineTypes
    exit 0
fi

if [ "$COMMAND" = "scale" ]; then
    ScaleCluster "$2"
    exit 0
fi

echo 'please specify create or delete'
exit 1

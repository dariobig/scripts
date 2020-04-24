#!/bin/bash
CLUSTER_NAME=dario-dev-dataproc-1
REGION=us-central1
ZONE=us-central1-a
NODES=2
PREEMPTIBLE=8
WORKER=n1-standard-4
MASTER=n1-standard-4
STORAGE_BUCKET=dario-dev-us-central1
DISK_SIZE=1TB
SCRIPT_FILE=`basename "$0"`
REMOTE_SCRIPT="gs://${STORAGE_BUCKET}/scripts/${SCRIPT_FILE}"


function UploadScript {
    CMD="gsutil cp ${SCRIPT_FILE} ${REMOTE_SCRIPT}"
    echo $CMD
    $CMD
}

function DownloadScript {
    CMD="gsutil cp ${REMOTE_SCRIPT} ${SCRIPT_FILE}"
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

function CreateCluster {
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
        --num-secondary-workers $PREEMPTIBLE \
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
        echo 'creating cluster ... '
        CreateCluster
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

echo 'please specify create or delete'
exit 1

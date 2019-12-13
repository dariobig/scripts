gcloud auth print-access-token | docker login -u oauth2accesstoken \
                --password-stdin https://gcr.io

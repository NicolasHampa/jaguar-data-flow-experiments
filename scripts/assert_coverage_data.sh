#! /bin/bash

if [ -z "$1" ] ; then
    echo "Defects4J dataset path is missing! Execution has been stopped."
    exit 1
fi

dataset_base_path=$1

for project_base_path in `find $dataset_base_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version in `find $project_base_path -maxdepth 1 -mindepth 1 -type d`
    do
        python3 assert_jaguar.py "$project_version/jaguar"
    done
done

echo "Successfully generated coverage report csv file!"
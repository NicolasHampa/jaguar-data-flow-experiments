#! /bin/bash

if [ -z "$1" ] ; then
    echo "Repository root path is missing! Execution has been stopped."
    exit 1
fi

dataset_path="$1/dataset"
scripts_path="$1/scripts"
reports_path="$1/reports"

if [ -f $reports_path/assert_coverage.csv ] ; then
    rm $reports_path/assert_coverage.csv
fi

for project_path in `find $dataset_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        python3 $scripts_path/assert_jaguar.py "$project_version_path/jaguar"
    done
done

echo "Successfully generated coverage report csv file!"
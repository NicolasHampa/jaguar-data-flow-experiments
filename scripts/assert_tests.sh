#! /bin/bash

if [ -z "$1" ] ; then
    echo "Repository root path is missing! Execution has been stopped."
    exit 1
fi

dataset_path="$1/dataset"
scripts_path="$1/scripts"
reports_path="$1/reports"

if [ -f $reports_path/assert_tests.csv ] ; then
    rm $reports_path/assert_tests.csv
fi

for project_path in `find $dataset_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_version=${project_version_path_array[((index-1))]}
        strlen=${#project_version}
        project_version_type=${project_version: -1}
        if [ $project_version_type = "b" ]; then
            python3 $scripts_path/assert_failing_tests.py $project_version_path
        fi
    done
done

echo "Successfully generated csv tests report file!"
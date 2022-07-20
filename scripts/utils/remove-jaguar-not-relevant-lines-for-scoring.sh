#! /bin/bash
#
# Most of the Jaguar matrix files contains compressed lines that
# are not relevant for the execution of the scoring pipeline
# 
# Removes compressed Jaguar lines from previous filtered matrix files
#

if [ -z "$1" ] ; then
    echo "Jaguar repository root path is missing! Execution has been stopped."
    exit 1
fi

repository_root_path=$1

for project_path in `find $repository_root_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        if [ "${project_version_path: -1}" == "b" ]; then
            IFS='/' read -ra project_version_path_array <<< "$project_version_path"
            index=${#project_version_path_array[@]}
            project_name=${project_version_path_array[((index-2))]}
            project_version=${project_version_path_array[((index-1))]}

            printf "\n===================================================================\n"
            echo $project_name"/"$project_version
            echo "==================================================================="

            jaguar_matrix_version_path=$project_version_path"/jaguar/.jaguar/matrix/relevant"
            mkdir -p $jaguar_matrix_version_path/filtered

            for matrix_file_path in `find $jaguar_matrix_version_path -maxdepth 1 -mindepth 1 -type f`
            do

                IFS='/' read -ra matrix_file_path_array <<< "$matrix_file_path"
                index=${#matrix_file_path_array[@]}
                matrix_file_name=${matrix_file_path_array[((index-1))]}
                
                # echo "$jaguar_matrix_version_path/filtered/$matrix_file_name"
                while read line; do
                    if [ "${line:0:1}" != "=" ]; then
                        echo $line >> "$jaguar_matrix_version_path/filtered/$matrix_file_name"
                    fi
                done < $matrix_file_path
            done
        fi
    done
done

#! /bin/bash

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

            printf "\n===================================================================\n" >> "$HOME/report3.txt"
            echo $project_name"/"$project_version >> "$HOME/report3.txt"
            echo "===================================================================" >> "$HOME/report3.txt"

            jaguar_matrix_version_path=$project_version_path"/jaguar/.jaguar/matrix"
            for matrix_file_path in `find $jaguar_matrix_version_path -maxdepth 1 -mindepth 1 -type f`
            do
                IFS='/' read -ra matrix_file_path_array <<< "$matrix_file_path"
                index=${#matrix_file_path_array[@]}
                matrix_file_name=${matrix_file_path_array[((index-1))]}
                
                echo "===================================================================" >> "$HOME/report3.txt"
                echo $matrix_file_name >> "$HOME/report3.txt"
                echo "===================================================================" >> "$HOME/report3.txt"
                
                failing_test=0
                while read line; do
                    if [ "${line: -1}" == "-" ]; then
                        printf "CONTAINS FAILING TEST\n\n" >> "$HOME/report3.txt"
                        failing_test=1
                        break
                    elif [ "${line: -1}" == "+" ]; then
                        continue
                    else
                        printf "INVALID_CHAR ${line: -1}\n\n" >> "$HOME/report3.txt"
                        break
                    fi
                done < $matrix_file_path
                
                if [ $failing_test == 0 ]; then
                    printf "NOT CONTAINS FAILING TEST\n\n" >> "$HOME/report3.txt"
                fi
            done
        fi
    done
done

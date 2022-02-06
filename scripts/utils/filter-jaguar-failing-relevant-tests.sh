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

            printf "\n===================================================================\n"
            echo $project_name"/"$project_version
            echo "==================================================================="

            jaguar_matrix_version_path=$project_version_path"/jaguar/.jaguar/matrix"
            jaguar_spectra_version_path=$project_version_path"/jaguar/.jaguar/spectra"

            mkdir $jaguar_matrix_version_path/relevant
            mkdir $jaguar_spectra_version_path/relevant

            for matrix_file_path in `find $jaguar_matrix_version_path -maxdepth 1 -mindepth 1 -type f`
            do

                IFS='/' read -ra matrix_file_path_array <<< "$matrix_file_path"
                index=${#matrix_file_path_array[@]}
                matrix_file_name=${matrix_file_path_array[((index-1))]}
                
                relevant_test=0
                while read line; do
                    if [ "${line: -1}" == "-" ]; then
                        IFS=' ' read -ra line_array <<< "$line"

                        for dua_coverage in "${line_array[@]}"
                        do
                            if [ "$dua_coverage" == "1" ]; then
                                relevant_test=1

                                echo $matrix_file_name
                                cp $matrix_file_path $jaguar_matrix_version_path/relevant

                                spectra_file_name=${matrix_file_name%".matrix"}".spectra"
                                echo $spectra_file_name
                                cp $jaguar_spectra_version_path/$spectra_file_name $jaguar_spectra_version_path/relevant

                                break
                            fi
                        done

                        if [ $relevant_test == 1 ]; then
                            break
                        fi
                    fi
                done < $matrix_file_path
            done
        fi
    done
done

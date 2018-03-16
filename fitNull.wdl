task fitNull {
	File genotype_file
	File phenotype_file
	String outcome_name
	String outcome_type
	String? covariates_string
	File? sample_file
	String label
	File kinship_matrix
	String id_col

	Int memory
	Int disk

	command {
		echo "Input files" > fitNull.log
		echo "genotype_file: ${genotype_file}" >> fitNull.log
		echo "phenotype_file: ${phenotype_file}" >> fitNull.log
		echo "outcome_name: ${outcome_name}" >> fitNull.log
		echo "outcome_type: ${outcome_type}" >> fitNull.log
		echo "covariates_string: ${covariates_string}" >> fitNull.log
		echo "sample_file: ${sample_file}" >> fitNull.log
		echo "label: ${label}" >> fitNull.log
		echo "kinship_matrix: ${kinship_matrix}" >> fitNull.log
		echo "id_col: ${id_col}" >> fitNull.log
		echo "memory: ${memory}" >> fitNull.log
		echo "disk: ${disk}" >> fitNull.log
		echo "" >> fitNull.log
		dstat -c -d -m --nocolor 10 1>>fitNull.log &
		R --vanilla --args ${genotype_file} ${phenotype_file} ${outcome_name} ${outcome_type} ${default="NA" covariates_string} "NA" "NA" "NA" ${default="NA" sample_file} ${label} ${kinship_matrix} ${id_col} < /singleVariantAssociation/genesis_nullmodel.R
	}

	runtime {
		docker: "tmajarian/singlevariantassociation:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory}G"
	}

	output {
		File model = "${label}_null.RDa"
		File log_file = "fitNull.log"
	}
}

workflow w_assocTest {
	# fitNull inputs
	Array[File] these_genotype_files
	File this_phenotype_file
	String this_outcome_name
	String this_outcome_type
	String? this_covariates_string
	File? this_sample_file
	String this_label
	File this_kinship_matrix
	String this_id_col
	
	# inputs to all
	Int this_memory
	Int this_disk

	File null_genotype_file = these_genotype_files[0]


	call fitNull {
		input: genotype_file = null_genotype_file, phenotype_file = this_phenotype_file, outcome_name = this_outcome_name, outcome_type = this_outcome_type, covariates_string = this_covariates_string, sample_file = this_sample_file, label = this_label, kinship_matrix = this_kinship_matrix, id_col = this_id_col, memory = this_memory, disk = this_disk
	}

}

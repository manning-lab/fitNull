task conditionalPhenotype {
	Array[File] genotype_files
	File phenotype_file
	String id_col
	File? sample_file
	String snps
	String label

	Int disk

	command {
		echo "Input files" > conditionalPhenotype_out.log
		echo "genotype_files: ${sep="," genotype_files}" >> conditionalPhenotype_out.log
		echo "phenotype_file: ${phenotype_file}" >> conditionalPhenotype_out.log
		echo "id_col: ${id_col}" >> conditionalPhenotype_out.log
		echo "sample_file: ${sample_file}" >> conditionalPhenotype_out.log
		echo "snps: ${snps}" >> conditionalPhenotype_out.log
		echo "label: ${label}" >> conditionalPhenotype_out.log
		echo "disk: ${disk}" >> conditionalPhenotype_out.log
		echo "" >> conditionalPhenotype_out.log
		dstat -c -d -m --nocolor 10 1>>conditionalPhenotype_out.log &
		R --vanilla --args ${sep="," genotype_files} ${phenotype_file} ${id_col} ${default="NA" sample_file} ${snps} ${label} < /singleVariantAssociation/preprocess_conditional.R
	}

	runtime {
		docker: "manninglab/singlevariantassociation:latest"
		disks: "local-disk ${disk} SSD"
		memory: "10 GB"
		bootDiskSizeGb: 20
	}

	output {
		File new_phenotype_file = "${label}_phenotypes.csv"
		File alt_ref = "${label}_alleles.txt"
		File log_file = "conditionalPhenotype_out.log"
	}
}

task fitNull {
	File genotype_file
	File? phenotype_file
	String? outcome_name
	String? outcome_type
	String? covariates_string
	String? conditional_string
	String? ivars_string
	String? group_var
	File? sample_file
	String label
	File? kinship_matrix
	String? id_col

	Int memory
	Int disk

	command {
		echo "Input files" > fitNull_out.log
		echo "genotype_file: ${genotype_file}" >> fitNull_out.log
		echo "phenotype_file: ${phenotype_file}" >> fitNull_out.log
		echo "outcome_name: ${outcome_name}" >> fitNull_out.log
		echo "outcome_type: ${outcome_type}" >> fitNull_out.log
		echo "covariates_string: ${covariates_string}" >> fitNull_out.log
		echo "conditional_string: ${conditional_string}" >> fitNull_out.log
		echo "ivars_string: ${ivars_string}" >> fitNull_out.log
		echo "group_var: ${group_var}" >> fitNull_out.log
		echo "sample_file: ${sample_file}" >> fitNull_out.log
		echo "label: ${label}" >> fitNull_out.log
		echo "kinship_matrix: ${kinship_matrix}" >> fitNull_out.log
		echo "id_col: ${id_col}" >> fitNull_out.log
		echo "memory: ${memory}" >> fitNull_out.log
		echo "disk: ${disk}" >> fitNull_out.log
		echo "" >> fitNull_out.log
		dstat -c -d -m --nocolor 10 1>>fitNull_out.log &
		R --vanilla --args ${genotype_file} ${phenotype_file} ${outcome_name} ${outcome_type} ${default="NA" covariates_string} ${default="NA" conditional_string} ${default="NA" ivars_string} ${default="NA" group_var} ${default="NA" sample_file} ${label} ${kinship_matrix} ${id_col} < /singleVariantAssociation/genesis_nullmodel.R
	}

	runtime {
		docker: "manninglab/singlevariantassociation:latest"
		disks: "local-disk ${disk} SSD"
		memory: "${memory} GB"
		bootDiskSizeGb: 20
	}

	output {
		File model = "${label}_null.RDa"
		File log_file = "fitNull_out.log"
	}
}

workflow w_assocTest {
	# conditionalPhenotype inputs
	String? these_snps


	# fitNull inputs
	Array[File] these_genotype_files
	File this_phenotype_file
	String this_outcome_name
	String this_outcome_type
	String? this_covariates_string
	String? this_ivars_string
	String? this_group_var
	File? this_sample_file
	String this_label
	File this_kinship_matrix
	String this_id_col
	
	# inputs to all
	Int this_fitnull_memory
	Int this_disk

	File null_genotype_file = these_genotype_files[0]

	if(defined(these_snps)) {

		call conditionalPhenotype {
			input: genotype_files = these_genotype_files, phenotype_file = this_phenotype_file, id_col = this_id_col, sample_file = this_sample_file, snps = these_snps, label = this_label, disk = this_disk
		}
		
		call fitNull as fitNullConditional {
			input: genotype_file = null_genotype_file, phenotype_file = conditionalPhenotype.new_phenotype_file, outcome_name = this_outcome_name, outcome_type = this_outcome_type, covariates_string = this_covariates_string, conditional_string = these_snps, ivars_string = this_ivars_string, group_var = this_group_var, sample_file = this_sample_file, label = this_label, kinship_matrix = this_kinship_matrix, id_col = this_id_col, memory = this_fitnull_memory, disk = this_disk
		}
	}

	if (!defined(these_snps)) {
		
		call fitNull {
			input: genotype_file = null_genotype_file, phenotype_file = this_phenotype_file, outcome_name = this_outcome_name, outcome_type = this_outcome_type, covariates_string = this_covariates_string, conditional_string = these_snps, ivars_string = this_ivars_string, group_var = this_group_var, sample_file = this_sample_file, label = this_label, kinship_matrix = this_kinship_matrix, id_col = this_id_col, memory = this_fitnull_memory, disk = this_disk
		}
	}
}

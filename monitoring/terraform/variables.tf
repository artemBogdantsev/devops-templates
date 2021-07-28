# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "account_file_path" {
	description = "Default location of the auth file for the Service Account used for the GKE cluster"
	type 		= string
	default 	= "~/.gcp/gcp-sa-prod.json"
}

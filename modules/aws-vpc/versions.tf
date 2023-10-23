/**
  * <!-- Include all providers and version constraints for this module here.
  *      Don't be too restrictive with the versions unless you have a good
  *      reason... Consumers of the module can set more restrictive
  *      constraints. -->
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
  required_version = "~>1.5"
}

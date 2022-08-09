/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/

resource "random_pet" "this" {
  keepers = {
    time = timestamp()
  }
}

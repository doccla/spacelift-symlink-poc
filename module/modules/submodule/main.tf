resource "null_resource" "hello" {
  triggers = {
    var = var.a_common_variable
  }
}

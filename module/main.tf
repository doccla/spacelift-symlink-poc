module "child_module" {
  source = "./modules/submodule"

  a_common_variable = var.a_common_variable
}

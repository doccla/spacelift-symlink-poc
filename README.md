# Spacelift symlink bug

This repository showcases a problem when using symlinks in Terraform modules
published to the Spacelift Terraform registry. It's a simple demonstration
inspired by a larger example encountered in practice.

## Repo structure

The repo tree is as follows:

```
.
├── .gitignore
├── does-not-work
│   ├── .terraform
│   ├── .terraform.lock.hcl
│   └── main.tf
├── module
│   ├── .spacelift
│   │   └── config.yml
│   ├── child_variables.tf -> modules/submodule/variables.tf
│   ├── main.tf
│   ├── modules
│   │   └── submodule
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── terraform.tf
│   │       └── variables.tf
│   └── outputs.tf
└── works
    ├── .terraform
    ├── .terraform.lock.hcl
    └── main.tf

9 directories, 13 files

```

## Overview

- The main module contains a submodule.
- This submodule features a variable that the parent module also wants to expose.
- A symlink is used to import this variable definition from the child module to the parent.

## Reproducing the issue

1. The [`./works`](./works) example references the module locally and works correctly:

   ```
   module "example" {
     source = "../module"
   ```

2. The [`./does-not-work`](./does-not-work) example refers to the Spacelift-published module and faces an issue when applying:

   ```
   module "example" {
     source = "spacelift.io/doccla/symlink_bug_demo_module/null"
   ```

	 Applying this results in:

   ```
   $ tf apply
   ╷
   │ Error: Unsupported argument
   │
   │   on main.tf line 4, in module "example":
   │    4:   a_common_variable = "hello, world"
   │
   │ An argument named "a_common_variable" is not expected here.
   ```

	 The linked file (child_variables.tf) is present after fetching the module
	 but is empty, suggesting that the Spacelift publishing process doesn't
	 handle symlinks properly:


   ```
   -rwxrwxrwx@ 1  0    17  Aug 11:35 child_variables.tf
   -rw-rw-r--@ 1  104  17  Aug 11:35 main.tf
   drwxr-xr-x@ 3  96   17  Aug 11:35 modules
   -rw-rw-r--@ 1  54   17  Aug 11:35 outputs.tf
   ```

## Expected behaviour

Spacelift follows the symlink and includes its contents in the published
module, to match the behaviour that Terraform follows when synthesising the
module using a local relative path reference.

## Why?

Symlinks are often used to avoid repetitive code in Terraform modules. Here are
two scenarios where this pattern proves useful:

1. **Submodule variable exposure**: a submodule gets isolated to allow
   selective import of behaviour. However, key functionality from a submodule may
   be exposed in a parent module, and it is appropriate to expose its public API
   surface. This can be readily achieved and kept in sync by using a symlink.

1. **Terragrunt input variables**: in a Terragrunt setup with multiple modules,
		 symlinks can provide a consistent set of input variables that configure
		 the environment for each child module, such as providing cloud provider
		 account details. This helps in avoiding redundancy (we can potentially get
		 around this one using a `generate` block).

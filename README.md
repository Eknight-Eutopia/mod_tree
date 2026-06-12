# mod_tree
Generate kernel modules dependencies tree 

## Usage
```shell
❯ ./mod_tree.sh
Usage:
    ./mod_tree.sh [-d module_dir] [-o output_file] <module|module.ko>

Examples:
    ./mod_tree.sh ext4

    ./mod_tree.sh ./msm_kgsl.ko

    ./mod_tree.sh -d ./rootfs/lib/modules msm_kgsl

    ./mod_tree.sh -d ./rootfs/lib/modules -o result.txt msm_kgsl
```

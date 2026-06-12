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
## Example
```shell
❯ ./mod_tree.sh -d ./rootfs/lib/modules/6.12.69-android16-6-maybe-dirty-4k/extra/soc-repo  ./rootfs/msm_kgsl.ko
msm_kgsl
    ├── socinfo
    │   └── smem
    ├── llcc-qcom
    ├── qcom-dcvs
    ├── governor_msm_adreno_tz
    │   └── qcom-scm
    ├── qcom-scm
    ├── cmd-db
    ├── msm_performance
    │   ├── qcom-pmu-lib
    │   └── sched-walt
    ├── qcom_aoss
    │   └── qcom_ipc_logging
    │       └── minidump
    │           ├── debug_symbol
    │           └── smem
    ├── mem_buf_dev
    │   └── secure_buffer
    │       └── qcom-scm
    ├── qcom_iommu_util
    │   └── qcom-scm
    ├── clk-qcom
    ├── secure_buffer
    │   └── qcom-scm
    ├── mdt_loader
    │   └── qcom-scm
    ├── minidump
    │   ├── debug_symbol
    │   └── smem
    ├── qcom_va_minidump
    │   └── minidump
    │       ├── debug_symbol
    │       └── smem
    └── coresight
```

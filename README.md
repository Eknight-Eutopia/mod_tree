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
msm-kgsl
    ├── socinfo
    │   └── smem
    ├── llcc-qcom
    │   └── socinfo
    │       └── smem
    ├── qcom-dcvs
    │   └── dcvs-fp
    │       ├── qcom-rpmh
    │       │   ├── qcom-ipc-logging
    │       │   │   └── minidump
    │       │   │       ├── debug-symbol
    │       │   │       └── smem
    │       │   └── cmd-db
    │       └── cmd-db
    ├── governor-msm-adreno-tz
    │   └── qcom-scm
    ├── qcom-scm
    ├── cmd-db
    ├── msm-performance
    │   ├── qcom-pmu-lib
    │   │   ├── qcom-scmi-client
    │   │   └── qcom-llcc-pmu
    │   └── sched-walt
    │       └── socinfo
    │           └── smem
    ├── qcom-aoss
    │   └── qcom-ipc-logging
    │       └── minidump
    │           ├── debug-symbol
    │           └── smem
    ├── mem-buf-dev
    │   └── secure-buffer
    │       └── qcom-scm
    ├── qcom-iommu-util
    │   └── qcom-scm
    ├── clk-qcom
    │   ├── gdsc-regulator
    │   │   ├── proxy-consumer
    │   │   └── debug-regulator
    │   └── icc-clk
    ├── secure-buffer
    │   └── qcom-scm
    ├── mdt-loader
    │   └── qcom-scm
    ├── minidump
    │   ├── debug-symbol
    │   └── smem
    ├── qcom-va-minidump
    │   └── minidump
    │       ├── debug-symbol
    │       └── smem
    └── coresight
```

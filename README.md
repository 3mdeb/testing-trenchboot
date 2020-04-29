Trenchboot Testing Infrastructure
=====================================

This repository contains testing infrastructure related to [Trenchboot](https://github.com/3mdeb/meta-trenchboot)
project. Tests are written for usage with [Remote Testing Environment](https://shop.3mdeb.com/product/rte/)
in [Robot Framework](https://github.com/robotframework/robotframework).
These [platforms](#supported-platforms) are currently supported.

Preparing platform for testing
------------------------------

The DUT needs to be connected with RTE as specified in [apu-rte connection
manual](docs/apu2-rte_connection.md). Coreboot must be flashed for [meta-trenchboot
yocto tests](os/yocto_install.robot) to work correctly. To do that use
[coreboot/flash_coreboot.robot](coreboot/flash_coreboot.robot).
After that os tests can be run correctly.


Virtualenv initialization
-------------------------

```
git clone https://github.com/3mdeb/testing-trenchboot.git
cd testing-trenchboot
git submodule update --init --checkout
virtualenv -p $(which python2) robot-venv
source robot-venv/bin/activate
pip install -r requirements.txt
```

Using docker instead of virtualenv
----------------------------------

Just replace the `robot` with:
`docker run --rm -it -v ${PWD}:${PWD} -w ${PWD} 3mdeb/rf-docker`

Running test cases
------------------

Below commands assume you have virtualenv with robot framework activated.

```
# run test `FB1.3...` from foo suite bar test cases
robot -t "FB1.3*" -L TRACE -v rte_ip:$RTE_IP -v config:$CONFIG -v fw_file:$FW_FILE ./foo/bar.robot
# run all test cases from foo suite bar
robot -L TRACE -v rte_ip:$RTE_IP -v config:$CONFIG -v fw_file:$FW_FILE ./foo/bar.robot
```

Of course you have to replace:

* `$RTE_IP` - which is your RTE IP address, you can find it in
  [variables.robot](variables.robot),
* `$CONFIG` - platform specific configuration for importing correct keywords and
  variables. List of [supported platforms](#supported-platforms) is shown below
  and all config files are located in `platform-configs/`,
* `$FW_FILE` - path to firmware you want to use for given suite.


For example, to flash coreboot, type:

* method #1 (binary file exists locally on the user computer):

```
robot -L TRACE -v rte_ip:192.168.4.172 -v config:apu2 -v fw_file:./coreboot.rom ./coreboot/flash_coreboot.robot
```

* method #2 (binary file will be downloaded via FTP):

```
robot -L TRACE -v rte_ip:192.168.4.172 -v config:apu2 -v fw_version:v4.10.0.1 ./coreboot/flash_coreboot.robot
```

Supported platforms
-------------------

Manufacturer| Platform     | Firmware                 | Support | $CONFIG
------------|--------------|--------------------------|---------|--------------------------
PC Engines  | apu2 | PC Engines coreboot fork | Full    | `apu2`
Asrock      | R1000V | - | None | `r1000v`
ASUS        | KGPE-D16 | - | None | `kgpe-d16`
Supermicro  | m11sdv-8ct-ln4f | - | None | `supermicro`

* _Full_ - supported all test suites,
* _Limited_ - supported basic tests - flashing firmware (coreboot/uefi) etc. [WIP],
* _None_ - platform not yet supported (lack of config/tests) but listed for
 enabling in the near future. This may also means that all of tests and configs
 are in the `dev` stage.

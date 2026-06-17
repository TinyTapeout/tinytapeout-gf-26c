# Build Tiny Tapeout with LibreLane

## Environment setup

```bash
export LIBRELANE_ROOT=`pwd`/librelane
export PDK_ROOT=`pwd`/.ciel
export PDK=gf180mcuD
export PDK_VERSION=98203068432a374192b0163c6c7d491207b52992
export TT_CONFIG=gf180mcuD.yaml:../../mux_overrides.yaml
```

Then install LibreLane with Nix, as explained [here](https://librelane.readthedocs.io/en/latest/installation/nix_installation/index.html).

## Repository setup

First, make sure that you have checked out the submodules:

```bash
git submodule update --init
```

Then install all the Python dependencies. You may want to use a virtual enviroment (venv or similar).

```bash
pip install -r tt-multiplexer/py/requirements.txt -r tt/requirements.txt
```

## Installing the PDK

The gf180mcuD PDK is fetched with [Ciel](https://github.com/fossi-foundation/ciel)
at the version pinned above. `ciel` ships inside the LibreLane Nix shell:

```bash
nix-shell ${LIBRELANE_ROOT}/shell.nix --run "ciel enable --pdk gf180mcu --pdk-root ${PDK_ROOT} ${PDK_VERSION} --include-libraries all"
```

This downloads and enables `${PDK_ROOT}/gf180mcuD`.

## Fetching the projects

Run the following commands to generate the configuration for building Tiny Tapeout:

```bash
python tt/configure.py --update-shuttle
```

## Harden

```bash
nix-shell ${LIBRELANE_ROOT}/shell.nix --run "python -m librelane --manual-pdk tt/rom/config.json"
nix-shell ${LIBRELANE_ROOT}/shell.nix --run "cd tt-multiplexer/ol2/tt_ctrl && python build.py"
nix-shell ${LIBRELANE_ROOT}/shell.nix --run "cd tt-multiplexer/ol2/tt_mux && python build.py"
python tt/configure.py --copy-macros
nix-shell ${LIBRELANE_ROOT}/shell.nix --run "cd tt-multiplexer/ol2/tt_top && python build.py"
```

You'll find the final GDS in `tt-multiplexer/ol2/tt_top/runs/RUN_*/final/gds/openframe_project_wrapper.gds`. To copy it (along with the lef, gl verilog, and spef files), run:

```bash
python tt/configure.py --copy-final-results
```

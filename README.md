# FloatSmith

This project provides source-to-source tuning and transformation of
floating-point code for mixed precision using three existing tools: 1)
[CRAFT](https://github.com/crafthpc/craft), 2)
[ADAPT](https://github.com/LLNL/adapt-fp), and 3)
[TypeForge](https://github.com/rose-compiler/rose-develop/tree/master/projects/typeforge).


## Prerequisites

The CRAFT search depends on [Ruby](https://www.ruby-lang.org/en/) 2.0 or later,
ADAPT depends on [CoDiPack](https://github.com/SciCompKL/CoDiPack), and
TypeForge depends on the [Rose](http://rosecompiler.org)
compiler framework. CoDiPack and Rose are installed automatically if you do not
already have ADAPT and TypeForge installed. See the sections below for more
details.


## Getting Started

If you have any of the previously mentioned tools already installed, you may use
your existing installation as follows:

1) For CRAFT, make sure that the main `craft` search driver script is accessible
in your `PATH`.

2) For ADAPT, make sure the environment variables `CODIPACK_HOME` and
`ADAPT_HOME` environment variables are set to the root of the CoDiPack and ADAPT
repositories, respectively (ADAPT depends on
[CoDiPack](https://github.com/SciCompKL/CoDiPack)).

3) For TypeForge, make sure that the `typeforge` executable is accessible in
your `PATH`.

If any of these tools are not available, FloatSmith will install them the first
time it is run (before running analysis). Note that TypeForge depends on Rose,
which is a fairly large download and may require a significant amount of time to
build depending on how powerful your system is.


## Using FloatSmith

To run, execute the `floatsmith` top-level driver script from the folder where
you want to perform tuning. This script will ensure all three tools are
available (installing them in the repository `tools` folder if they are not) and
then run the interactive driver.

Here is the basic sequence followed by FloatSmith:

1) Run TypeForge in exploratory mode to find all possible double-to-float
floating-point conversions.

2) (Optional) Run ADAPT to narrow search space.

3) Run CRAFT in variable mode, using TypeForge to prototype mixed-precision
configurations.

The driver will ask you various questions about your program and generate
several other helper scripts that manage running the various parts of the
pipeline. By default these scripts and all intermediate/final results are placed
in a folder called `.floatsmith` in the current folder, but this can be changed
if desired by providing a different path when the script asks for it.

After running TypeForge (and optionally ADAPT), the CRAFT search will commence,
printing various status information while it is running. When it is finished,
you will find your final recommended configuration in the `.floatsmith/final`
subfolder. You may examine `.floatsmith/search/craft_final.json` for a list of
converted variables.


### Batch Mode

If you would prefer a more non-interactive experience, you can invoke FloatSmith
in batch mode using the `-B` option. This will accept all default options unless
otherwise specified on the command line. Run with `-h` for a complete list of
options available to customize the run without using the interactive prompts.
Note that you must at minimum specify the `--run` option. See the `run.sh`
scripts in the demo folders for examples of how to use this mode.


### Using Docker

If you have Docker installed, you can run FloatSmith on Ubuntu through a
container. Run `floatsmith-docker` to launch the container. That script will
build the image first if necessary; be aware that it may take quite a while and
the resulting image is quite large (~2GB). It will automatically mount your
current working folder into the container and any file system changes will take
place as the user who builds the image. If you'd like to run the provided demos,
they are also mounted in `/opt/floatsmith/demos`.

Alternatively, you can pull and run the latest image directly from Docker Hub:

```
docker pull lam2mo/floatsmith
docker run -it lam2mo/floatsmith
```

The demos are provided in the image home folder in this version. Although your
local filesystem can still be mounted into this version (command below), it is
not built with your local user and therefore should be used with caution when
modifying files on your system.

```
docker run -v $(pwd):/local -it lam2mo/floatsmith
```

### FloatSmith File Structure

This section contains a description of the file structure created by FloatSmith
during analysis, with hints about how to debug issues that may arise while
analyzing your program.

The entire structure is rooted at the folder provided by you at the beginning of
the run. By default, this folder is called `.floatsmith` and located in the
folder from which you run the analysis. This is often the folder containing your
program, and so we use the dot (hidden) filename to prevent the analysis files
from being included when your project is recursively copied to temporary
locations.

Here are the files and folders that will be present in this top-level folder
after a successful search:

* `acquire.sh`, `build.sh`, `run.sh`, and `verify.sh` - These are path-agnostic
  scripts that 1) copy your project files to the current folder, 2) build your
  project, 3) run the resulting program with a representative input, and 4)
  verify that the output has an acceptable level of accuracy. These scripts are
  populated automatically based on your answers to the questions asked by
  FloatSmith, or may be passed as command-line parameters in batch mode. There
  are reasonable defaults for all of them except the run script, which must be
  specified manually in all cases. (Acquire default: recursive copy from current
  folder; build default: run "`make`"; verify default: compare to original
  output.)

* `phase1.log`, `phase2.log`, `phase3.log` - Output/error logs for the three
  phases descripted in the section above entitled "Using FloatSmith". These help
  with identifying issues when the search does not finish successfully.

* `typeforge_vars.json` and `craft_initial.json` - Primary output of phase 1
  (variable discovery), and primary input for phase 3 (mixed-precision search),
  respectively. The former is a list of all replacements that TypeForge has
  reported are possible, and the latter is the list of potential replacements
  that CRAFT will consider at the beginning of the search. These are often
  identical down to formatting differences unless you have chosen to ignore
  variables or are using the results of an ADAPT run.

* `baseline` - Temporary files created while running your program unchanged to
  get a baseline output for comparison. If this is present, the output file here
  (e.g., `stdout`) is probably referenced in `verify.sh`.

* `sanity` - Temporary files created while running your program to test the
  scripts generated by FloatSmith. Usually these files should be identical to
  the ones in `baseline` (if the latter are present; they are not created if you
  have an alternative method of checking correctness besides comparing the
  entire program output). You should be able to reproduce this folder manually
  by running the four autogenerated scripts (acquire/build/run/verify) in
  sequence from an empty folder. Checking these files or attempting to
  re-generate them will likely be helpful if the sanity check fails and you are
  trying to figure out why.

* `initial` - Temporary files created by phase 1 (the TypeForge run to detect
  all possible replacements). `initial.json` is the plugin file used to invoke
  TypeForge. You can re-run this phase manually using the `run.sh` script inside
  this folder to help with debugging if TypeForge fails to find valid
  replacements.

* `autodiff` - Temporary files created by phase 2 (the ADAPT instrumentation and
  execution). `instrument.json` is the plugin file used to invoke TypeForge, and
  the `rose_*` files are the instrumented source of your program. You can re-run
  this phase manually using the `run.sh` script inside this folder to help with
  debugging if the ADAPT run fails.

* `search` - Temporary and output files created by phase 3 (the CRAFT
  mixed-precision search). You can re-run this phase manually using the `run.sh`
  script inside this folder to help with debugging if the search fails. The
  other contents of this folder are described in the "CRAFT File Structure"
  section below.


### CRAFT File Structure

This section contains a description of the file structure created by CRAFT
 during analysis, with hints about how to
debug issues that may arise while analyzing your program.

Inside the root of the CRAFT search (e.g., `.floatsmith/search` by default),
there are several folders (`aborted`, `failed`, `passed`, and `best`) that may
contain configuration files in JSON format depending on the results of the
search. If short enough, the names of these files will help you infer what
replacements they contain, but you can always check the JSON directly to see the
actual changes even if the filename isn't useful (e.g., it has become too long
and been converted to a hash value). FloatSmith provides a variety of helpful
scripts for examining and manipulating configuration files; see the
[`scripts`](https://github.com/crafthpc/floatsmith/tree/master/scripts) folder
of this repository.

Building and testing one of these configurations manually is relatively simple
thanks to the provided `craft_builder` and `craft_driver` scripts, which are
generally wrappers around the FloatSmith acquire/build and run/verify scripts,
respectively. Create a temporary folder and invoke those scripts from that
folder, providing the desired configuration as a parameter to the builder
script. Here is an example that runs the failed "`p`" configuration from the
`sanity` demo:

    mkdir tmp
    cd tmp
    ../craft_builder ../failed/1_p.json
    ../craft_driver

The configuration tests themselves take place in the `run` folder, and the
temporary folders are usually deleted after the test finishes to save space;
however, if the search terminates abnormally during the search, the active
folders will still be here, which is useful for debugging. The baseline and
final run folders are also always kept for later reference. If you desire, you
can keep ALL of these temporary results by using the "`-k`" CRAFT command-line
parameter; edit `run.sh` and re-run it. Be warned that this may use a
prohibitive amount of hard drive space if your program is large.


If successful, the CRAFT search folder will also contain `craft_final.json` and
`craft_final.cfg`, both of which represent the recommended configuration (as
determined by the search strategy you chose). The former is in a format usable
by TypeForge to build the configuration while the latter is in a format viewable
using the CRAFT configuration editor GUI (which you can build from the `viewer`
folder of the CRAFT repository if you have Java installed). There is also a
`final` folder, which contains the final configuration with the transformation
already applied (although see "Known Issues" below for a caveat).

There will also be several `craft.*` files, which are mostly for temporary
internal storage during the search. These usually will not be of interest to end
users.


## Known Issues

The final search output (usually in `.floatsmith/search/final`) will have
formatting differences from your original source code. This is due to the way
the Rose framework (and therefore TypeForge) re-emits modified code. The
framework provides a mechanism that should allow us eventually to re-emit the
code with no or minimal formatting modifications (along with a clean diff from
your original code), but we have not yet had the time to implement this in
TypeForge.


## Getting Involved

To get involved, submit an issue or contact the authors directly.


## Contributing

To contribute, submit a pull request or email the authors directly.


## Licensing

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>.


## Acknowledgements

The following contributors have been involved in some part of this project:

* [Mike Lam](https://github.com/lam2mo) - author of CRAFT and co-author of ADAPT
* [Markus Schordan](https://github.com/mschordan) - author of TypeForge
* [Harshitha Menon](https://github.com/harshithamenon) - author of ADAPT
* [Logan Moody](https://github.com/logangregorym) - contributor to CRAFT and
  ADAPT, author of JSON interchange format, and author of TypeForge installation
  script
* Nathan Pinnow - contributor to TypeForge
* [Tristan Vanderbruggen](https://github.com/tristanvdb) - contributor to
  TypeForge


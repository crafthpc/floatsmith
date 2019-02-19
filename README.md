# FloatSmith

This project provides source-to-source tuning and transformation of
floating-point code for mixed precision using three existing tools: 1)
[CRAFT](https://github.com/crafthpc/craft), 2)
[ADAPT](https://github.com/LLNL/adapt-fp), and 3)
[TypeForge](https://github.com/rose-compiler/rose-develop/tree/master/projects/typeforge).


## Prerequisites

The CRAFT search depends on [Ruby](https://www.ruby-lang.org/en/) 2.0 or later,
ADAPT depends on [CoDiPack](https://github.com/SciCompKL/CoDiPack), and
TypeForge depends on the [Rose](https://github.com/rose-compiler/rose-develop/)
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
in a folder called `.craft` in the current folder, but this can be changed if
desired by providing a different path when the script asks for it.

After running TypeForge (and optionally ADAPT), the CRAFT search will commence,
printing various status information while it is running. When it is finished,
you will find your final recommended configuration in the `.craft/final`
subfolder. You may examine `.craft/search/craft_final.json` for a list of
converted variables.


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


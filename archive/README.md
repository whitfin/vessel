## vessel-arch

Provides several Mix tasks to ease the creation of Vessel projects for use with Hadoop. You will likely not need this if your MapReduce does not integrate with Hadoop.

### Available Tasks

|    Mix Task    |                             Description                              |
|:--------------:|:--------------------------------------------------------------------:|
|  local.vessel  |  Installs the most recent version of the Vessel archive from GitHub  |
|   vessel.new   |      Creates a new template Vessel project for Hadoop Streaming      |

### Building

To build and install locally, just do as follows:

```bash
$ cd archive/
$ mix archive.build
$ mix archive.install
```

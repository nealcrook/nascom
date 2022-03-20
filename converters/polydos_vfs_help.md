# polydos_vfs help

This tool has extensive build-in help. The text of "help" command is shown
below, but there is additional detailed help for each of the commands listed and also for various advanced topics like file formats and conversions.

````
$ ./polydos_vfs
polydos_vfs: help

polydos_vfs allows manipulation of up to 4 virtual drives, numbered 0 through 3.
Each drive can be associated with a file on the host filesystem. Files can be
copied between virtual drives or transferred between virtual drives and the host
filesystem. Virtual drives can be inspected and manipulated.

Usage:

    polydos_vfs
    polydos_vfs < script
    polydos_vfs foo.bin
    polydos_vfs *.bin

The first form starts an interactive session.
The second form runs a sequence of commands from a file (See 'help scripts').
The third form treats foo.bin as a disk image and does a mount/info/check/dir/exit.
The fourth form treats *.bin as a set of disk images and does a
mount/info/check/dir/exit on each image in turn.

Commands are:

    mount      - associate disk image with virtual drive number
    umount     - disconnect disk image from drive number
    info       - report virtual drives currently mounted
    clone      - make copy of virtual drive
    new        - create new empty disk image (optional size specification)
    copy       - copy file(s) from one virtual drive to another
    rename     - change name of file on virtual drive
    name       - change disk name
    type       - view file from virtual drive (optional format conversion)
    export     - copy file from virtual drive to local file system (optional format conversion)
    import     - copy file from local file system to virtual drive (optional format conversion)
    dir        - directory of virtual drive
    hdir       - directory of local file system
    delete     - set delete (D) flag on file(s) from virtual drive
    undelete   - clear delete (D) flag on file(s) from virtual drive
    lock       - set lock (L) flag on file(s) from virtual drive
    unlock     - clear lock (L) flag on file(s) from virtual drive
    attrib     - change load/execution address on file(s) from virtual drive
    pack       - remove deleted files and free up disk space and directory entries
    create     - create file from sector(s) on the free list
    repair     - interactively correct directory structure errors
    check      - check integrity of virtual drive
    scrub      - null out deleted file names and unused sectors
    uppercase  - treat all PolyDos file specifiers as upper-case
    exit       - unmount all mounted drives and leave polydos_vfs
    quit       - synonym for exit
    help       - this is it.

Other help topics: files formats comments conversions scripts

Type help <command name> or help <topic> for more help.
polydos_vfs: quit
````


When working on a Cypress PSoC project, building the code with PSoC Creator is
extremely slow, especially when it's running in a VM.  I made this small tool
that generates Makefiles from PSoC Creator's ```.cyprj``` files, so that I could build
the code on my Linux host.  Since the code is in a shared directory with the
VM, I can still use PSoC Creator to do the programming.

The goal is not to replace PSoC Creator completely, but just to ease the
software development part, especially removing the roundtrips to between my
editor and PSoC Creator when fixing build errors.  PSoC Creator offers the
possibility to export the "workspace" to a few IDEs, including Eclipse, but I
found their integration a bit sketchy, and it's Windows-specific anyway.

After building on the Linux host, PSoC creator seems to recognize the .o files
that were built by the Makefile and does not rebuild them.  It only does the
final linking again, which is not too long.  The GCC version I use on my host
(5.3.0) is different from the one bundled with PSoC creator, but the
application seems to work fine anyway.  I probably wouldn't trust it for an
official release/build, at this point doing a full build in PSoC Creator would
be safer.

Note that this was done with PSoC 5 in mind, things may be a bit different for
other chips.

# How to install

Simply run (with sudo if needed):

    $ python setup.py install

# How to use

Go to your PSoC Creator project directory, where the ```.cyprj``` file can be found.

You will need to copy one library, ```CyComponentLibrary.a```, from the PSoC Creator
installation to your project directory.  However, PSoC Creator provides multiple
versions of it, for various configurations and processors.  To know which one<
you need, search for ```CyComponentLibrary``` in the build log.  For example, mine
was at

    C:\Program Files (x86)\Cypress\PSoC Creator\3.3\PSoC Creator\psoc\content\CyComponentLibrary\CyComponentLibrary.cylib\CortexM3\ARM_GCC_493\Debug\CyComponentLibrary.a

Once this is done, the tool can be used like so:

    $ cyprj-to-makefile myproject.cyprj > Makefile
    $ make

# Notes

This tool is not made nor endorsed by Cypress, so please do not direct your questions about it to them.

# Usage

1. Install required Python packages

```bash
pip install -r requirements.txt
```

2. Start the GUI

```bash
python Py-CMeditor.py
```

## Troubleshoot

If you use `virtualenv` to manage Python dependencies, you might encounter following
issue:

    This program needs access to the screen. Please run with a
    Framework build of python, and only when you are logged in
    on the main display of your Mac.

This is a known bug of `virtualenv`. Read more about how to troubleshoot this issue
at [this link](https://matplotlib.org/faq/osx_framework.html#osxframework-faq).
In short, you can use the Framework build of python and set the $PYTHONHOME
to still have access to the right python dependencies by starting the GUI with
following command:

```bash
PYTHONHOME=$VIRTUAL_ENV /usr/local/bin/python Py-CMeditor.py
```
#-----------------------------------------------------------------------------------------------------------------------

# Update

In the dev stage of this GUI it is better to use Anaconda and create a virtual environment (see the bottom of Readme in parent Bathymetry dir).

The virtualenv problem occurs on Macs and can be overcome by using pythonw. NB. the 'w'. E.g. 
    pythonw Py-CMeditor.py

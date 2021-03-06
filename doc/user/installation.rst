Installation
============

Prerequisites
-------------
Running RAMP requires a working Python 3 installation. If you are unfamiliar with \
Python, this can be easily obtianed from the `Python website <https://www.python.org/>`_ \
or as part of the `Anaconda package <https://www.anaconda.com/>`_  which comes \
preloaded with many useful libraries.

In addition to Python 3, RAMP is parallelized using the OpenCL API. To install the \
Python port of the OpenCL bindings and compile the OpenCL kernels used by RAMP, it \
will be necessary to install the OpenCL SDK appropriate to the vendor of the hardware \
you intend to run RAMP on. At the time of writing, these SDKs can be obtained from

    - `Intel OpenCL SDK <https://software.intel.com/en-us/intel-opencl/>`_
    - `NVIDIA CUDA Toolkit <https://developer.nvidia.com/cuda-downloads/>`_
    - `AMD GPUOpen SDK <https://gpuopen.com/compute-product/opencl-sdk/>`_

If during the installation or execution of RAMP you are recieving errors relating to \
the header file 'CL\\cl.h' it is likely your OpenCL SDK is incorrectly installed.

Obtaining RAMP
--------------
RAMP is most easily obtained by cloning the public GitHub repository::

 $ git clone https://github.com/gcassella/RAMP.git

Otherwise the package can be downloaded from the `GitHub page <https://github.com/gcassella/RAMP>`_ \
in a .zip archive. The package can then be installed via::

 $ cd RAMP
 $ python setup.py install

To ensure the package has been installed correctly, try running one of the examples \
found in the 'examples' directory::

 $ cd examples
 $ python LET_RAMP.py

If this prompts you to select your OpenCL device and then spits out a handful of \
detector image plots, everything is installed correctly!

Jupyter notebooks
-----------------
Some of the instructional examples for RAMP are presented as `Jupyter <https://jupyter.org/>`_ \
notebooks. These are interactive Python environments that allow code to be presented, edited, \
and ran alongside relevant text and graphical outputs.

To install Jupyter (assuming you followed the instructions above and have a functional \
Python installation) run::

 $ pip install jupyterlab

Jupyter can then be run via::

 $ cd %your_ramp_directory_here%/examples/%example_you_want_to_run%
 $ jupyter notebook

This will open a page in your default web browser from which you can select the \
example notebook and run the interactive Python therein.
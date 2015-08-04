from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize


extensions = [Extension("ccda", ["cython_wrapper/ccda.pyx"], libraries=["cda4PyQt"])]

setup(ext_modules=cythonize(extensions))
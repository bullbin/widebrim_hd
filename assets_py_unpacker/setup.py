try:
    from setuptools import setup, Extension
except ImportError:
    from distutils.core import setup, Extension

from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        r"lib\\lt2_decrypt.pyx", compiler_directives={"language_level": "3"}
    )
)
from setuptools import setup, find_packages

setup(
    name = "CyprjToMakefile",
    version = "0.1",
    author = "Simon Marchi",
    author_email = "simon.marchi@polymtl.ca",
    description = "Generate Makefiles from Cypress cyprj files.",
    license = "GPLv3",
    url = "https://github.com/simark/cyprj-to-makefile",
    packages = find_packages(),
    install_requires = ['jinja2'],
    package_data = {
		'cyprj_to_makefile': ['Makefile.tpl'],
	},
	entry_points = {
		'console_scripts': [
			'cyprj-to-makefile = cyprj_to_makefile.cyprj_to_makefile:main',
		],
	},
)

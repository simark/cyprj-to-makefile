#!/usr/bin/env python3

import argparse
import collections
import xml.etree.ElementTree as ET
from jinja2 import Environment
import os
from pkg_resources import resource_string


def visit(node, cb):
    for child in node:
        visit(child, cb)

    cb(node)


class SourceFile:

    def __init__(self, path):
        self.path = path


def fix_slashes(s):
    return s.replace('\\', '/')


class Visitor:
    interesting_build_actions = ['C_FILE', 'ARM_C_FILE', 'GNU_ARM_ASM_FILE']

    def __init__(self):
        self.source_files = collections.defaultdict(list)

        self.last_source_file = None
        self.last_build_action = None
        self.include_dirs = []
        self.additional_cflags = set()

    def __call__(self, node):
        type_name = node.attrib.get('type_name')

        if node.tag == 'Hidden':
            self.last_hidden = node.attrib['v'] == 'True'
        if node.tag == 'build_action':
            self.last_build_action = node.attrib['v']
        elif type_name == 'CyDesigner.Common.ProjMgmt.Model.CyPrjMgmtItem':
            self.last_source_file = fix_slashes(node.attrib['persistent'])
        elif type_name == 'CyDesigner.Common.ProjMgmt.Model.CyPrjMgmtFile':
            assert self.last_build_action is not None
            assert self.last_source_file is not None

            if self.last_build_action in self.interesting_build_actions:
                # Little hack... I don't know how to exclude C_FILEs from
                # components.
                if '/API/' not in self.last_source_file and not self.last_hidden:
                    self.source_files[self.last_build_action].append(
                        self.last_source_file)
        elif node.tag == 'name_val_pair':
            name = node.attrib['name']
            value = node.attrib['v']

            if 'Additional Include Directories' in name:
                self.include_dirs += [fix_slashes(x.strip())
                                      for x in value.split(';') if len(x) > 0]
            elif 'Warnings as Errors' in name:
                self.additional_cflags.add('-Werror')
            elif 'Warning Level' in name:
                if value == 'High':
                    self.additional_cflags.add('-Wall')
                else:
                    self.additional_cflags.add('-w')
            elif 'Generate Debugging Information' in name:
                self.additional_cflags.add('-g')


def replace_ext(f, new_ext):
    root, old_ext = os.path.splitext(f)
    return root + '.' + new_ext


def prefix(s, p):
    return p + s


def main():
    # Parse args
    argparser = argparse.ArgumentParser(
        description='Generate Makefile from Cypress cyprj.')
    argparser.add_argument('cyprj', help='The cyprj file.')
    argparser.add_argument(
        '--cross', help='Cross compiler prefix (default: arm-none-eabi).',
        default='arm-none-eabi')
    argparser.add_argument(
        '--objdir',
        help='The output directory (default: ./CortexM3/ARM_GCC_493/Debug).',
        default='./CortexM3/ARM_GCC_493/Debug')
    args = argparser.parse_args()

    # Prepare template environment
    env = Environment()
    env.filters['basename'] = os.path.basename
    env.filters['replace_ext'] = replace_ext
    env.filters['prefix'] = prefix

    projname, unused = os.path.splitext(os.path.basename(args.cyprj))

    template_str = resource_string(__name__, 'Makefile.tpl').decode()
    template = env.from_string(template_str)

    # Parse and visit the cyprj XML file
    tree = ET.parse(args.cyprj)
    visitor = Visitor()
    visit(tree.getroot(), visitor)

    # Output the Makefile
    print(template.render(projname=projname,
                          cross=args.cross,
                          objdir=args.objdir,
                          visitor=visitor))

if __name__ == '__main__':
    main()

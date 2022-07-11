#!/usr/bin/python3
#
# For a Defects4J bug (provided in input args),
# shows the user the patch (the diff between the bug and the fix).
#
# Requirements:
#   - Python 3
#
#   - The defects4j command (of the Defects4J repository that is populated with
#     all real and artificial faults) must be on the PATH.
#
#   - The default diff viewer is meld -- you can change the diff viewer by
#     setting the --diff-viewer option.
#
# Usage:
#   python view-patch-for-d4j-bug.py --project <D4J project name> --version  <D4J project version>
#

import subprocess
import argparse

PIPE = subprocess.PIPE

def check_out_dirs(project, version, dir_format):
  buggy_dir = dir_format.format(project=project, version=version, bf='b')
  fixed_dir = dir_format.format(project=project, version=version, bf='f')
  subprocess.call(
    'defects4j checkout -p {} -v {}b -w {}'.format(
      project, version, buggy_dir),
    shell=True)
  subprocess.call(
    'defects4j checkout -p {} -v {}f -w {}'.format(
      project, version, fixed_dir),
    shell=True)

def compare_dirs(project, version, dir_format):
  buggy_dir = dir_format.format(project=project, version=version, bf='b')
  fixed_dir = dir_format.format(project=project, version=version, bf='f')
  print_source_dir_command = 'cd {} && defects4j export -p dir.src.classes'.format(buggy_dir)
  p = subprocess.Popen(print_source_dir_command, shell=True, stdout=PIPE, stderr=PIPE)
  source_dir = p.communicate()[0].decode().strip()
  subprocess.call(
    '{view} {buggy}/{source} {fixed}/{source} &'.format(
      view=args.diff_viewer,
      buggy=buggy_dir,
      fixed=fixed_dir,
      source=source_dir),
    shell=True)
  
def remove_check_out_dirs(project, version, dir_format):
  buggy_dir = dir_format.format(project=project, version=version, bf='b')
  subprocess.call('rm -rf {}'.format(buggy_dir), shell=True)
  fixed_dir = dir_format.format(project=project, version=version, bf='f')
  subprocess.call('rm -rf {}'.format(fixed_dir), shell=True)

if subprocess.call('which defects4j', shell=True, stdout=PIPE) != 0:
  raise RuntimeError('defects4j command not found (try adding defects4j/framework/bin to your path)')

parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--checkout-dir-format', default='/tmp/view_patch_for_d4j_bug_{project}_{version}{bf}', help="path to check projects out into, e.g. `--checkout-dir-format '/tmp/{project}_{version}{bf}'` will check things out into /tmp/Lang_1b, /tmp/Chart_2f, etc.")
parser.add_argument('--diff-viewer', default='meld')

args = parser.parse_args()

check_out_dirs(args.project, args.version, args.checkout_dir_format)

compare_dirs(args.project, args.version, args.checkout_dir_format)

input('Showing patch for {}/{}: Press any key to continue... \n'.format(args.project, args.version)).strip()

remove_check_out_dirs(args.project, args.version, args.checkout_dir_format)

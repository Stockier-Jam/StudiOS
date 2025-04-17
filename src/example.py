'''
 Copyright (C) 2025  Your FullName

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 3.

 c-ide-app is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''

import sys
sys.dont_write_bytecode = True #Prevent creation of .pyc files to avoid permission issues
import io
import traceback

def run_code_with_input(code, user_input=""):
    # Ensure user input ends with a newline so input() works
    if not user_input.endswith("\n"):
        user_input += "\n"

    # Redirect stdin to simulate user input
    sys.stdin = io.StringIO(user_input)

    # Redirect stdout and stderr to capture output
    stdout = io.StringIO()
    stderr = io.StringIO()

    # Backup original streams
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    original_stdin = sys.stdin

    sys.stdout = stdout
    sys.stderr = stderr

    try:
        exec(code, {})
    except Exception:
        traceback.print_exc(file=stderr)

    # Restore original streams
    sys.stdout = original_stdout
    sys.stderr = original_stderr
    sys.stdin = original_stdin

    output = stdout.getvalue()
    error = stderr.getvalue()

    if error:
        return f"⚠️ Error:\n{error}"
    return output


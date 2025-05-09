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

import pyotherside
import sys
import io
import traceback
from queue import Queue
import code
import builtins # used to intercept calls to input()
import threading
import time

class InteractiveRunner(code.InteractiveConsole):
    def __init__(self, code_text):
        super().__init__(locals={})
        self.code_lines = code_text.splitlines()
        self.stdin_queue = Queue()
        self.output = io.StringIO()
        self.error = io.StringIO()
        self.waiting_for_input = False
        self.is_done = False
        self.buffer = []  # For multiline input
        self.current_line = 0
        self.input_handled_event = threading.Event()
        self.lock = threading.Lock()

    def patched_input(self, prompt=""):
        # Write directly to real stdout, not the captured one
        sys.stdout.write(prompt)
        sys.stdout.flush()

        #self.waiting_for_input = True
        self.input_handled_event.clear()

        user_input = self.stdin_queue.get()
        #self.waiting_for_input = False
        self.input_handled_event.set()
        #self.output.write(f"user input: {user_input}")

        return user_input


    def run(self):
        sys_stdout, sys_stderr, sys_stdin = sys.stdout, sys.stderr, sys.stdin
        sys.stdout = self.output
        sys.stderr = self.error
        sys.stdin = self

        original_input = builtins.input
        builtins.input = self.patched_input

        try:
            while self.current_line < len(self.code_lines):

                line = self.code_lines[self.current_line]
                self.buffer.append(line)
                source = "\n".join(self.buffer)

                more = self.runsource(source, "<input>", "single")

                if not more:
                    #self.output.write(f"Not more: {line}")
                    self.buffer.clear()
                    self.current_line = self.current_line + 1
                    continue

                time.sleep(0.05)

        except EOFError:
            # Handle EOFError if input reaches EOF or other terminal issues
            self.output.write("[ERROR] EOFError encountered while running the source.\n")
        except Exception as e:
            # Catch other exceptions and log them
            self.error.write(f"[ERROR] Exception in runsource(): {e}\n")
            traceback.print_exc(file=self.error)
            self.is_done = True

        finally:
            captured_stdout = self.output.getvalue()
            captured_stderr = self.error.getvalue()

            # Flush all prints to output buffer before resetting stdout
            sys.stdout.flush()
            sys.stderr.flush()

            # Save current output(before resetting stdout)
            captured_stdout = self.output.getvalue()
            captured_stderr = self.error.getvalue()

            # Rewind buffers before reset (safeguard)
            self.output.seek(0)
            self.error.seek(0)

            # Reset streams
            sys.stdout = sys_stdout
            sys.stderr = sys_stderr
            sys.stdin = sys_stdin
            builtins.input = original_input

            self.output = io.StringIO()
            self.output.write(captured_stdout)
            self.error = io.StringIO()
            self.error.write(captured_stderr)


    def submit_input(self, user_input):
        self.stdin_queue.put(user_input)

    def get_output(self):
        out = self.output.getvalue()
        err = self.error.getvalue()
        return out
        #self.output = io.StringIO()
        #self.error = io.StringIO()
        #if err:
        #    return f"⚠️ Error:\n{err}"
        #if not out:
        #    return "Waiting for input..."

        #return out


# Global session store
runner_instance = None


def start_code(code):
    global runner_instance
    runner_instance = InteractiveRunner(code)

    thread = threading.Thread(target=runner_instance.run)
    thread.daemon = True
    thread.start()

    output = runner_instance.get_output()
    return output

def send_input(user_input):
    if user_input:
        global runner_instance
        if runner_instance is not None and not runner_instance.is_done:
            runner_instance.submit_input(user_input)

            #Wait until the input has been handled by the existing thread
            runner_instance.input_handled_event.wait(timeout=3)
            time.sleep(0.1)

            return runner_instance.get_output()
        return "No active session or program has finished"


def save_file(file_path, content):
    try:
        dir_name = os.path.dirname(file_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Saved successfully to: {file_path}")
        return "File saved successfully!"
    except Exception as e:
        print(f"Error saving: {e}")
        return f"Error saving file: {str(e)}"


def load_file(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()  # Return the file content as a string
    except Exception as e:
        return f"Error loading file: {str(e)}"

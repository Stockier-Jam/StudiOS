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
import os

class InteractiveRunner(code.InteractiveConsole):
    def __init__(self, code_text):
        super().__init__(locals={})
        self.code_lines = code_text.splitlines()
        self.stdin_queue = Queue()
        self.output = io.StringIO()
        self.error = io.StringIO()
        self.is_done = False
        self.waiting_for_input = False
        self.buffer = []  # For multiline input
        self.current_line = 0
        self.input_handled_event = threading.Event()

    def patched_input(self, prompt=""):
        #self.output.write(f"{prompt}")
        self.output.write(prompt)
        self.output.flush()
        #print(prompt, end='', flush=True)  # prints prompt once, without double-buffering

        self.waiting_for_input = True
        self.input_handled_event.clear() # Reset event

        user_input = self.stdin_queue.get()
        #extra_input = self.stdin_queue.get()
        #self.output.write(f"🔧 [DEBUG] Received input: {user_input}\n")
        #self.output.write(f"🔧 [DEBUG] Received extra input: {extra_input}\n")
        self.waiting_for_input = False
        self.input_handled_event.set() # Let other know input was handled

        return user_input

    def run(self):
        print("[THREAD STARTED] Runner thread is alive.")
        sys_stdout, sys_stderr, sys_stdin = sys.stdout, sys.stderr, sys.stdin
        sys.stdout = self.output
        sys.stderr = self.error
        sys.stdin = self

        original_input = builtins.input
        builtins.input = self.patched_input

        skip_execution = False

        try:
            while self.current_line < len(self.code_lines):
                # Pause unitl input is received
                if self.waiting_for_input:
                    time.sleep(0.05)
                    continue

                if skip_execution:
                    skip_execution = False  # skip 1 iteration
                    continue

                line = self.code_lines[self.current_line]
                #self.output.write(f"{self.code_lines}")
                #self.locals['input'] = self.patched_input
                #self.output.write(f"🔧 [DEBUG] Executing line {self.current_line}: {repr(line)}\n")

                self.buffer.append(line)
                #self.output.write(f" Line now: {(line)}\n")
                #self.output.write(f" Buffer now: {repr(self.buffer)}\n")
                source = "\n".join(self.buffer)
                #self.waiting_for_input = True
                more = self.runsource(source, "<input>", "single")

                if not more:
                    #self.output.write(f"🔧 [DEBUG] Executing complete statement from line {self.current_line}: {repr(line)}\n")
                    self.buffer.clear()
                    self.current_line = self.current_line + 1
                else:
                    self.current_line = self.current_line + 1
                    skip_execution = True

                    if self.waiting_for_input:
                        skip_execution = True

        except EOFError:
            pass
        except Exception as e:
            self.error.write(f"[ERROR] Exception in run(): {e}\n")
            traceback.print_exc(file=self.error)
            self.is_done = True
        finally:
            captured_stdout = self.output.getvalue()
            captured_stderr = self.error.getvalue()
            #self.output.write("🔍 [DEBUG] captured_stdout contents1:\n"+ repr(captured_stdout))


            # Flush all prints to output buffer before resetting stdout
            sys.stdout.flush()
            sys.stderr.flush()

            # Save current output(before resetting stdout)
            captured_stdout = self.output.getvalue()
            captured_stderr = self.error.getvalue()
            #self.output.write("🔍 [DEBUG] captured_stdout contents1:\n"+ repr(captured_stdout))

            # Rewind buffers before reset (safeguard)
            self.output.seek(0)
            self.error.seek(0)

            # Reset streams
            #self.output.write("🔍 [DEBUG] captured_stdout contents1:\n"+ repr(captured_stdout))
            sys.stdout = sys_stdout
            sys.stderr = sys_stderr
            sys.stdin = sys_stdin
            builtins.input = original_input

            # Re-buffer captured outputs so get_output() still works
            #self.output.write("🔍 [DEBUG] captured_stdout contents2:\n"+ repr(captured_stdout))

            self.output = io.StringIO()
            #self.output.write("🔍 [DEBUG] captured_stdout contents3:"+ repr(captured_stdout + "\n"))

            self.output.write(captured_stdout + "🔧 [DEBUG] Execution ended!!!!!\n")
            self.error = io.StringIO()
            self.error.write(captured_stderr)

    def submit_input(self, user_input):

        #print("[CHECK] Calling submit_input")
        #self.output.write(f"🔧 [DEBUG] Submitting input: {user_input}\n")
        #print("[CHECK] submit_input wrote to buffer")
        self.stdin_queue.put(user_input)
        return self.get_output()

    def get_output(self):
        out = self.output.getvalue()
        err = self.error.getvalue()
        return out
        #print("[DEBUG] get_output:", repr(out))
        self.output = io.StringIO()
        self.error = io.StringIO()
        #print("[DEBUG] get_output:", repr(out))
        if err:
            return f"⚠️ Error:\n{err}"
        if not out:
            return "Waiting for input..."
        return out

# Global session store
runner_instance = None


def start_code(code):
    global runner_instance
    runner_instance = InteractiveRunner(code)
    #runner_instance.output.write("🔧 [DEBUG] Code started\n")

    thread = threading.Thread(target=runner_instance.run)
    thread.daemon = True
    thread.start()

    output = runner_instance.get_output()
    #print("[Python DEBUG] Final output:\n", output)
    return output

def send_input(user_input):
    if user_input:
        global runner_instance
        if runner_instance is not None and not runner_instance.is_done:
            runner_instance.submit_input(user_input)
            #return user_input

            #Wait until the input has been handled by the existing thread
            runner_instance.input_handled_event.wait(timeout=3)
            time.sleep(0.1)

            return runner_instance.get_output()
        return "No active session or program has finished"

def save_file(file_path, content):
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w') as file:
            file.write(content)
        return "File saved successfully!"
    except Exception as e:
        return f"Error saving file: {str(e)}"

def load_file(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()  # Return the file content as a string
    except Exception as e:
        return f"Error loading file: {str(e)}"

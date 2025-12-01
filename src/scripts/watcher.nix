{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Watch directory for changes and run command, killing and restarting on new changes
    (writeShellScriptBin "watcher" ''
      if [ $# -lt 2 ]; then
          echo "Usage: watcher <directory>... -- <command>"
          echo "Watches one or more directories for changes and runs the specified command."
          echo "If changes occur while running, kills and restarts the command."
          echo ""
          echo "Examples:"
          echo "  watcher src/ -- 'cargo t'"
          echo "  watcher src/ posts/ -- 'cargo build'"
          exit 1
      fi

      DIRS=()
      COMMAND_PARTS=()
      FOUND_SEPARATOR=0

      # Parse arguments: directories before --, command after --
      for arg in "$@"; do
          if [ "$arg" = "--" ]; then
              FOUND_SEPARATOR=1
              continue
          fi

          if [ $FOUND_SEPARATOR -eq 0 ]; then
              DIRS+=("$arg")
          else
              COMMAND_PARTS+=("$arg")
          fi
      done

      if [ ''${#DIRS[@]} -eq 0 ]; then
          echo "Error: No directories specified"
          exit 1
      fi

      if [ ''${#COMMAND_PARTS[@]} -eq 0 ]; then
          echo "Error: No command specified after --"
          exit 1
      fi

      COMMAND="''${COMMAND_PARTS[*]}"

      # Validate directories
      for dir in "''${DIRS[@]}"; do
          if [ ! -d "$dir" ]; then
              echo "Error: Directory '$dir' does not exist."
              exit 1
          fi
      done

      echo "Watching directories:"
      for dir in "''${DIRS[@]}"; do
          echo "  - $dir"
      done
      echo "Command: $COMMAND"
      echo "Press Ctrl+C to stop"
      echo ""

      COMMAND_PID=0

      run_command() {
          if [ $COMMAND_PID -ne 0 ] && kill -0 $COMMAND_PID 2>/dev/null; then
              echo "Killing previous process (PID: $COMMAND_PID)..."
              kill $COMMAND_PID 2>/dev/null
              wait $COMMAND_PID 2>/dev/null
          fi

          echo "Running: $COMMAND"
          bash -c "$COMMAND" &
          COMMAND_PID=$!
      }

      # Run once initially
      run_command

      # Monitor for changes in all directories
      ${inotify-tools}/bin/inotifywait -m -r -e modify,create,delete,move "''${DIRS[@]}" 2>/dev/null | while read line; do
          echo ""
          echo "Change detected!"
          run_command
          echo ""
          echo "Waiting for changes..."
      done
    '')
  ];
}
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "payslips" ''
      set -euo pipefail

      if [ $# -ne 1 ]; then
        echo "Usage: payslips <zip-file>"
        echo "Example: payslips 'Electric Visions Ltd M1.zip'"
        exit 1
      fi

      ZIP="$1"
      if [ ! -f "$ZIP" ]; then
        echo "Error: File not found: $ZIP"
        exit 1
      fi

      BASENAME=$(basename "$ZIP")
      TAX_MONTH=$(echo "$BASENAME" | grep -oP 'M\K[0-9]+')

      if [ -z "$TAX_MONTH" ] || [ "$TAX_MONTH" -lt 1 ] || [ "$TAX_MONTH" -gt 12 ]; then
        echo "Error: Could not parse valid tax month (M1-M12) from filename: $BASENAME"
        exit 1
      fi

      # UK tax year: M1=April, M2=May, ..., M9=December, M10=January, M11=February, M12=March
      CAL_MONTH=$(( (TAX_MONTH + 2) % 12 + 1 ))
      CAL_MONTH=$(printf "%02d" "$CAL_MONTH")

      # Infer tax year start from current date
      CURRENT_MONTH=$(date +%-m)
      CURRENT_YEAR=$(date +%Y)
      if [ "$CURRENT_MONTH" -ge 4 ]; then
        TAX_YEAR_START=$CURRENT_YEAR
      else
        TAX_YEAR_START=$((CURRENT_YEAR - 1))
      fi

      # Calendar year: M1-M9 (Apr-Dec) use tax year start, M10-M12 (Jan-Mar) use next year
      if [ "$TAX_MONTH" -le 9 ]; then
        YEAR=$TAX_YEAR_START
      else
        YEAR=$((TAX_YEAR_START + 1))
      fi

      DEST="/data/documents/electricvisions/company/payslips/$YEAR"
      mkdir -p "$DEST"

      TMPDIR=$(mktemp -d)
      trap 'rm -rf "$TMPDIR"' EXIT

      ${unzip}/bin/unzip -q "$ZIP" -d "$TMPDIR"

      for PDF in "$TMPDIR"/*.pdf; do
        NAME=$(basename "$PDF" .pdf)
        LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        TARGET="$DEST/$CAL_MONTH-$LOWER.pdf"

        if [ -f "$TARGET" ]; then
          echo "Error: File already exists: $TARGET"
          exit 1
        fi

        mv "$PDF" "$TARGET"
        echo "$TARGET"
      done
    '')
  ];
}

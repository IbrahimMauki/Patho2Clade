#!/usr/bin/env bash
set -euo pipefail

##############################################
# Patho2Clade: Offline Pathogen Clade Finder
##############################################

usage() {
    echo "Usage: $0 --ref reference/cholerae/reference.fasta --tree reference/cholerae/o1_cholera.no_missing.pb --input example_data --threads 16"
    exit 1
}

# Default threads
THREADS=4

# ------------------------
# Parse arguments
# ------------------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ref) REF="$2"; shift ;;
        --tree) TREE="$2"; shift ;;
        --input) INPUT_DIR="$2"; shift ;;
        --threads) THREADS="$2"; shift ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# ------------------------
# Validate inputs
# ------------------------
[ -z "${REF:-}" ] && usage
[ -z "${TREE:-}" ] && usage
[ -z "${INPUT_DIR:-}" ] && usage

if [ ! -f "$REF" ]; then
    echo "ERROR: Reference genome not found: $REF"
    exit 1
fi

if [ ! -f "$TREE" ]; then
    echo "ERROR: Tree file not found: $TREE"
    exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "ERROR: Input directory not found: $INPUT_DIR"
    exit 1
fi

echo "=========================================="
echo "         Patho2Clade Pipeline"
echo "=========================================="
echo "Reference: $REF"
echo "Tree:      $TREE"
echo "Input:     $INPUT_DIR"
echo "Threads:   $THREADS"
echo "------------------------------------------"
echo ""

# ------------------------
# Process each FASTA file
# ------------------------
for FASTA in "$INPUT_DIR"/*.fasta; do

    FILE=$(basename "$FASTA")
    SAMPLE=${FILE%.fasta}
    OUTDIR="${INPUT_DIR}/${SAMPLE}"

    echo "------------------------------------------"
    echo "Processing sample: $SAMPLE"
    mkdir -p "$OUTDIR"

    # 1. SNIPPY
    echo "[1/4] Running Snippy..."
    snippy \
        --cpus "$THREADS" \
        --outdir "$OUTDIR" \
        --ref "$REF" \
        --ctgs "$FASTA" \
        --force

    if [ ! -f "$OUTDIR/snps.vcf" ]; then
        echo "Snippy failed for $SAMPLE — skipping."
        continue
    fi

    # 2. USHER
    echo "[2/4] Running Usher..."
    usher \
        -i "$TREE" \
        -v "$OUTDIR/snps.vcf" \
        -o "$OUTDIR/placement.pb"

    if [ ! -f "$OUTDIR/placement.pb" ]; then
        echo "Usher failed for $SAMPLE — skipping."
        continue
    fi

    # 3. Extract Clade
    echo "[3/4] Extracting lineage/clade..."
    TEMP="$OUTDIR/clade_temp.txt"
    matUtils summary -i "$OUTDIR/placement.pb" -C "$TEMP" >/dev/null 2>&1 || true

    CLADE="Unknown"

    if [ -s "$TEMP" ]; then
        LINE=$(grep -F "$SAMPLE" "$TEMP" | head -n 1 || true)
        if [ -n "$LINE" ]; then
            CLADE=$(echo "$LINE" | awk '{print $2}')
        fi
    fi

    echo "$CLADE" > "$OUTDIR/lineage.txt"
    rm -f "$TEMP"

    echo "Assigned clade: $CLADE"

    # 4. Create renamed FASTA
    echo "[4/4] Creating final FASTA..."
    NEW_FASTA="${INPUT_DIR}/${SAMPLE}_${CLADE}.fasta"
    cp "$FASTA" "$NEW_FASTA"

    echo "→ Output FASTA: $NEW_FASTA"
    echo "Done with sample: $SAMPLE"
    echo ""
done

echo "=========================================="
echo "       Patho2Clade Pipeline Complete"
echo "=========================================="

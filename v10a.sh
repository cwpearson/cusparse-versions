set -eou pipefail

export WORK_DIR=/rust/cwpears/cudas
SIMULTANEOUS_DOWNLOADS=4
SIMULTANEOUS_EXTRACTS=2

URLS=(
https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_410.48_linux
https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.105_418.39_linux.run
)

function cuda_release {
    version_re='/([0-9]+\.[0-9]+\.*[0-9]*)/'
    if [[ $1 =~ $version_re ]]; then
        echo ${BASH_REMATCH[1]}
    else
        echo "no match"
        exit 1
    fi
}

function download {
    wget --no-check-certificate -P "$WORK_DIR" -c $1
}
export -f download # export to subshells


function extract {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    echo "$fname -> $dirname"
    rm -rf "$dirname"

    if [[ $1 == *"1.105"* ]]; then
        $SHELL "$fname" --silent --override --toolkit --toolkitpath="$dirname" --defaultroot="$dirname"
    else
        $SHELL "$fname" --silent --override --toolkit --toolkitpath="$dirname"
    fi
}
export -f extract # export to subshells

function cuda_version {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    version=$(grep -roh -E 'CUDA_VERSION ([0-9]+)' $dirname/include | grep -o -E '[0-9]+')
    echo CUDA_VERSION '(CUDA API Version)' $version
}

function path_size {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    if stat -t $dirname/$2 >/dev/null 2>&1; then # tests if glob matches anything
        du -sLc $dirname/$2 | tail -n1 | cut -f1
    else
        echo 0
    fi
}

function so_size {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    du -sLc $dirname/lib64/$2*.so | tail -n1 | cut -f1
}

function dir_syms {
    shopt -s globstar
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    nm -D --defined-only $dirname/lib64/$2.so | wc -l
}

function cuda_size {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    du -s "$dirname" | cut -f1
}

function cusparse_size {
    so_size $1 libcusparse
}

function cublas_size {
    so_size $1 libcublas
}

function nvcc_size {
    path_size $1 bin/nvcc
}

function cufft_size {
    so_size $1 libcufft
}

function curand_size {
    so_size $1 libcurand
}

function cusolver_size {
    so_size $1 libcusolver
}

function npp_size {
    so_size $1 libnpp*
}

function nsight_compute_size {
    a=$(path_size $1 NsightCompute-*)
    b=$(path_size $1 nsight-compute-*)
    echo $a + $b | bc -l
}

function nsight_systems_size {
    a=$(path_size $1 NsightSystems-*)
    b=$(path_size $1 nsight-systems-*)
    echo $a + $b | bc -l
}

function cupti_size {
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    du -sLc $dirname/extras/CUPTI/lib64/libcupti*.so | tail -n1 | cut -f1
}

function gdb_size {
    path_size $1 bin/cuda-gdb*
}

function cudart_size {
    so_size $1 libcudart
}

function nvrtc_size {
    so_size $1 libnvrtc
}

function nsight_size {
    path_size $1 libnsight
}

function driver_size {
    echo 0
}

function pct {
    echo "x=$1 / $2 * 100; scale=2; x/1" | bc -l
}

function cusparse_syms {
    dir_syms $1 libcusparse
}

function cublas_syms {
    dir_syms $1 libcublas
}

function cusolver_syms {
    dir_syms $1 libcusolver
}

function cufft_syms {
    dir_syms $1 libcufft
}

function curand_syms {
    dir_syms $1 libcurand
}

function cudart_syms {
    dir_syms $1 libcudart
}

function cupti_syms {
    shopt -s globstar
    fname="$WORK_DIR"/$(basename $1)
    dirname="${fname%.*}"
    nm -D --defined-only $dirname/extras/CUPTI/lib64/libcupti*.so | wc -l
}

function npp_syms {
    dir_syms $1 libnpp*
}


function sym_table {
    printf "${TABLE_START}"
    printf "${ROW_START}${HCELL_START}CUDA Release${HCELL_END}"
    printf "${HCELL_START}cuSPARSE${HCELL_END}"
    printf "${HCELL_START}cuBLAS${HCELL_END}"
    printf "${HCELL_START}cuSOLVER${HCELL_END}"
    printf "${HCELL_START}cuFFT${HCELL_END}"
    printf "${HCELL_START}cuRAND${HCELL_END}"
    printf "${HCELL_START}cudart${HCELL_END}"
    printf "${HCELL_START}cupti${HCELL_END}"
    printf "${HCELL_START}npp${HCELL_END}"
    printf "${ROW_END}"
    for url in ${URLS[*]}; do
        _r=$(cuda_release "$url")
        printf "${ROW_START}"
        printf "${CELL_START}$_r${CELL_END}"
        printf "${CELL_START}$(cusparse_syms $url)${CELL_END}"
        printf "${CELL_START}$(cublas_syms $url)${CELL_END}"
        printf "${CELL_START}$(cusolver_syms $url)${CELL_END}"
        printf "${CELL_START}$(cufft_syms $url)${CELL_END}"
        printf "${CELL_START}$(curand_syms $url)${CELL_END}"
        printf "${CELL_START}$(cudart_syms $url)${CELL_END}"
        printf "${CELL_START}$(cupti_syms $url)${CELL_END}"
        printf "${CELL_START}$(npp_syms $url)${CELL_END}"
        printf "$ROW_END"
    done
    printf "${TABLE_END}"
}

function sym_html {
    TABLE_START="<table>\n"
    TABLE_END="</table>\n"
    ROW_START="<tr>"
    ROW_END="</tr>\n"
    HCELL_START="<th>"
    HCELL_END="</th>"
    CELL_START="<td>"
    CELL_END="</td>"
    sym_table
}

function sym_csv {
    TABLE_START=""
    TABLE_END=""
    ROW_START=""
    ROW_END="\n"
    HCELL_START=""
    HCELL_END=","
    CELL_START=""
    CELL_END=","
    sym_table
}

function size_table {
    printf "$TABLE_START"
    printf "$ROW_START"
    printf "${HCELL_START}CUDA Release${HCELL_END}"
    printf "${HCELL_START}Size (K)${HCELL_END}"
    printf "${HCELL_START}cuSPARSE${HCELL_END}"
    printf "${HCELL_START}cuBLAS${HCELL_END}"
    printf "${HCELL_START}nvcc${HCELL_END}"
    printf "${HCELL_START}cuFFT${HCELL_END}"
    printf "${HCELL_START}cuRAND${HCELL_END}"
    printf "${HCELL_START}cuSOLVER${HCELL_END}"
    printf "${HCELL_START}npp${HCELL_END}"
    printf "${HCELL_START}Nsight Compute${HCELL_END}"
    printf "${HCELL_START}Nsight Systems${HCELL_END}"
    printf "${HCELL_START}cuPTI${HCELL_END}"
    printf "${HCELL_START}CUDA GDB${HCELL_END}"
    printf "${HCELL_START}cudart${HCELL_END}"
    printf "${HCELL_START}nvrtc${HCELL_END}"
    printf "${HCELL_START}nsight${HCELL_END}"
    printf "${HCELL_START}driver${HCELL_END}"
    printf "$ROW_END"
    for url in ${URLS[*]}; do
        _r=$(cuda_release "$url")
        _c_s=$(cuda_size "$url")
        _cs_s=$(cusparse_size "$url")
        _cb_s=$(cublas_size "$url")
        _nvcc_s=$(nvcc_size "$url")
        _cufft_s=$(cufft_size "$url")
        _curand_s=$(curand_size "$url")
        _cusolver_s=$(cusolver_size "$url")
        _npp_s=$(npp_size "$url")
        _nsight_compute_s=$(nsight_compute_size "$url")
        _nsight_systems_s=$(nsight_systems_size "$url")
        _cupti_s=$(cupti_size "$url")
        _gdb_s=$(gdb_size "$url")
        _cudart_s=$(cudart_size "$url")
        _nvrtc_s=$(nvrtc_size "$url")
        _nsight_s=$(nsight_size "$url")
        _driver_s=$(driver_size "$url")
        printf "$ROW_START"
        printf "${CELL_START}$_r${CELL_END}"
        printf "${CELL_START}$_c_s${CELL_END}"
        printf "${CELL_START}$_cs_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cs_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_cb_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cb_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_nvcc_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_nvcc_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_cufft_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cufft_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_curand_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_curand_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_cusolver_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cusolver_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_npp_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_npp_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_nsight_compute_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_nsight_systems_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_nsight_systems_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_nsight_compute_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_cupti_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cupti_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_gdb_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_gdb_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_cudart_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_cudart_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_nvrtc_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_nvrtc_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_nsight_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_nsight_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "${CELL_START}$_driver_s"
        if [ ! "$SHOW_PCT" -eq 0 ]; then printf " ($(pct $_driver_s $_c_s)&#37)"; fi
        printf "$CELL_END"
        printf "$ROW_END"
    done
    printf "$TABLE_END"
}

function size_html {
    TABLE_START="<table>\n"
    TABLE_END="</table>\n"
    ROW_START="<tr>"
    ROW_END="</tr>\n"
    HCELL_START="<th>"
    HCELL_END="</th>"
    CELL_START="<td>"
    CELL_END="</td>"
    SHOW_PCT=1
    size_table
}

function size_csv {
    TABLE_START=""
    TABLE_END=""
    ROW_START=""
    ROW_END="\n"
    HCELL_START=""
    HCELL_END=","
    CELL_START=""
    CELL_END=","
    SHOW_PCT=0
    size_table
}

# echo "downloading"
# nice -n20 parallel -j${SIMULTANEOUS_DOWNLOADS} download {} ::: ${URLS[*]}

# echo "extracting"
# nice -n20 parallel -j${SIMULTANEOUS_EXTRACTS} extract {} ::: ${URLS[*]}

sym_html
sym_csv
size_html
size_csv

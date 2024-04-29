set -eou pipefail

SIMULTANEOUS_DOWNLOADS=4
SIMULTANEOUS_EXTRACTS=2

URLS=(
https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_550.54.15_linux.run
https://developer.download.nvidia.com/compute/cuda/12.3.2/local_installers/cuda_12.3.2_545.23.08_linux.run
https://developer.download.nvidia.com/compute/cuda/12.3.1/local_installers/cuda_12.3.1_545.23.08_linux.run
https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda_12.3.0_545.23.06_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.2/local_installers/cuda_12.2.2_535.104.05_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run
https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run
)

function cuda_release {
    version_re='/([0-9]+\.[0-9]+\.[0-9]+)/'
    if [[ $1 =~ $version_re ]]; then
        echo ${BASH_REMATCH[1]}
    else
        echo "no match"
        exit 1
    fi
}

function download {
    wget --no-check-certificate -c $1 2>&1 > /dev/null
}
export -f download # export to subshells


function extract {
    fname=$(basename $1)
    dirname="${fname%.*}"
    echo "$1 -> $dirname"
    rm -rf $dirname
    $SHELL $fname --extract=$PWD/$dirname
}
export -f extract # export to subshells

function cuda_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    version=$(grep -roh -E 'CUDA_VERSION ([0-9]+)' $dirname/cuda_cudart/include | grep -o -E '[0-9]+')
    echo CUDA_VERSION '(CUDA API Version)' $version
}

function dir_size {
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname/$2 | cut -f1)
    echo $size
}

function dir_syms {
    shopt -s globstar
    fname=$(basename $1)
    dirname="${fname%.*}"
    nm -D --defined-only $dirname/$2/**/*.so | wc -l
}

function cusparse_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    major=$(grep -roh -E 'CUSPARSE_VER_MAJOR ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    minor=$(grep -roh -E 'CUSPARSE_VER_MINOR ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    patch=$(grep -roh -E 'CUSPARSE_VER_PATCH ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    build=$(grep -roh -E 'CUSPARSE_VER_BUILD ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    echo $major.$minor.$patch.$build
}

function cublas_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    major=$(grep -roh -E 'CUBLAS_VER_MAJOR ([0-9]+)' $dirname/libcublas/include | grep -o -E '[0-9]+')
    minor=$(grep -roh -E 'CUBLAS_VER_MINOR ([0-9]+)' $dirname/libcublas/include | grep -o -E '[0-9]+')
    patch=$(grep -roh -E 'CUBLAS_VER_PATCH ([0-9]+)' $dirname/libcublas/include | grep -o -E '[0-9]+')
    build=$(grep -roh -E 'CUBLAS_VER_BUILD ([0-9]+)' $dirname/libcublas/include | grep -o -E '[0-9]+')
    echo $major.$minor.$patch.$build
}

function cusolver_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    major=$(grep -roh -E 'CUSOLVER_VER_MAJOR ([0-9]+)' $dirname/libcusolver/include | grep -o -E '[0-9]+')
    minor=$(grep -roh -E 'CUSOLVER_VER_MINOR ([0-9]+)' $dirname/libcusolver/include | grep -o -E '[0-9]+')
    patch=$(grep -roh -E 'CUSOLVER_VER_PATCH ([0-9]+)' $dirname/libcusolver/include | grep -o -E '[0-9]+')
    build=$(grep -roh -E 'CUSOLVER_VER_BUILD ([0-9]+)' $dirname/libcusolver/include | grep -o -E '[0-9]+')
    echo $major.$minor.$patch.$build
}

function cufft_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    major=$(grep -roh -E 'CUFFT_VER_MAJOR ([0-9]+)' $dirname/libcufft/include | grep -o -E '[0-9]+')
    minor=$(grep -roh -E 'CUFFT_VER_MINOR ([0-9]+)' $dirname/libcufft/include | grep -o -E '[0-9]+')
    patch=$(grep -roh -E 'CUFFT_VER_PATCH ([0-9]+)' $dirname/libcufft/include | grep -o -E '[0-9]+')
    build=$(grep -roh -E 'CUFFT_VER_BUILD ([0-9]+)' $dirname/libcufft/include | grep -o -E '[0-9]+')
    echo $major.$minor.$patch.$build
}

function cuda_size {
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname | cut -f1)
    echo $size
}

function cusparse_size {
    dir_size $1 libcusparse
}

function cublas_size {
    dir_size $1 libcublas
}

function nvcc_size {
    dir_size $1 cuda_nvcc/bin/nvcc
}

function cufft_size {
    dir_size $1 libcufft
}

function curand_size {
    dir_size $1 libcurand
}

function cusolver_size {
    dir_size $1 libcusolver
}

function npp_size {
    dir_size $1 libnpp
}

function nsight_compute_size {
    dir_size $1 nsight_compute
}

function nsight_systems_size {
    dir_size $1 nsight_systems
}

function cupti_size {
    dir_size $1 cuda_cupti
}

function gdb_size {
    dir_size $1 cuda_gdb
}

function cudart_size {
    dir_size $1 cuda_cudart
}

function nvrtc_size {
    dir_size $1 cuda_nvrtc
}

function nsight_size {
    dir_size $1 cuda_nsight
}

function driver_size {
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname/NVIDIA-* | cut -f1)
    echo $size
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
    dir_syms $1 cuda_cudart
}

function cupti_syms {
    dir_syms $1 cuda_cupti
}

function npp_syms {
    dir_syms $1 libnpp
}

echo "downloading"
nice -n20 parallel -j${SIMULTANEOUS_DOWNLOADS} download {} ::: ${URLS[*]}

echo "extracting"
nice -n20 parallel -j${SIMULTANEOUS_EXTRACTS} extract {} ::: ${URLS[*]}

function ver_table {
    printf "${TABLE_START}"
    printf "${ROW_START}"
    printf "${HCELL_START}CUDA Release${HCELL_END}"
    printf "${HCELL_START}cuSPARSE${HCELL_END}"
    printf "${HCELL_START}cuBLAS${HCELL_END}"
    printf "${HCELL_START}cuSOLVER${HCELL_END}"
    printf "${HCELL_START}cuFFT${HCELL_END}"
    printf "${ROW_END}"
    for url in ${URLS[*]}; do
        printf "${ROW_START}"
        printf "${CELL_START}$(cuda_release $url)${CELL_END}"
        printf "${CELL_START}$(cusparse_version $url)${CELL_END}"
        printf "${CELL_START}$(cublas_version $url)${CELL_END}"
        printf "${CELL_START}$(cusolver_version $url)${CELL_END}"
        printf "${CELL_START}$(cufft_version $url)${CELL_END}"
        printf "${ROW_END}"
    done
    printf "${TABLE_END}"
}

function ver_html {
    TABLE_START="<table>"
    TABLE_END="</table>\n"
    ROW_START="<tr>"
    ROW_END="</tr>\n"
    HCELL_START="<th>"
    HCELL_END="</th>"
    CELL_START="<td>"
    CELL_END="</td>"
    ver_table
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
    printf "${HCELL_START}cuSPARSE Size${HCELL_END}"
    printf "${HCELL_START}cuBLAS Size${HCELL_END}"
    printf "${HCELL_START}nvcc Size${HCELL_END}"
    printf "${HCELL_START}cuFFT Size${HCELL_END}"
    printf "${HCELL_START}cuRAND Size${HCELL_END}"
    printf "${HCELL_START}cuSOLVER Size${HCELL_END}"
    printf "${HCELL_START}npp Size${HCELL_END}"
    printf "${HCELL_START}Nsight Compute${HCELL_END}"
    printf "${HCELL_START}Nsight Systems${HCELL_END}"
    printf "${HCELL_START}cuPTI Size${HCELL_END}"
    printf "${HCELL_START}CUDA GDB Size${HCELL_END}"
    printf "${HCELL_START}cudart Size${HCELL_END}"
    printf "${HCELL_START}nvrtc Size${HCELL_END}"
    printf "${HCELL_START}nsight Size${HCELL_END}"
    printf "${HCELL_START}driver Size${HCELL_END}"
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

ver_html
sym_html
sym_csv
size_html
size_csv

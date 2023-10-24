set -eou pipefail

SIMULTANEOUS_DOWNLOADS=4
SIMULTANEOUS_EXTRACTS=2

URLS=(
https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run
https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.2/local_installers/cuda_12.2.2_535.104.05_linux.run
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
    wget --no-check-certificate -c $1
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

function cusparse_version {
    fname=$(basename $1)
    dirname="${fname%.*}"
    major=$(grep -roh -E 'CUSPARSE_VER_MAJOR ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    minor=$(grep -roh -E 'CUSPARSE_VER_MINOR ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    patch=$(grep -roh -E 'CUSPARSE_VER_PATCH ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    build=$(grep -roh -E 'CUSPARSE_VER_BUILD ([0-9]+)' $dirname/libcusparse/include | grep -o -E '[0-9]+')
    echo $major.$minor.$patch.$build
}

function cusparse_size {
    dir_size $1 libcusparse
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


function cublas_size {
    dir_size $1 libcublas
}

function cuda_size {
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname | cut -f1)
    echo $size
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

# echo "downloading"
# nice -n20 parallel -j${SIMULTANEOUS_DOWNLOADS} download {} ::: ${URLS[*]}

# echo "extracting"
# nice -n20 parallel -j${SIMULTANEOUS_EXTRACTS} extract {} ::: ${URLS[*]}

echo "<table>"
echo "<tr><th> CUDA Release </th><th> cuSPARSE Version </th><th> cuBLAS Version </th></tr>"
for url in ${URLS[*]}; do
    _r=$(cuda_release "$url")
    _cs_v=$(cusparse_version "$url")
    _cb_v=$(cublas_version "$url")
    echo "<tr><td> $_r </td><td> $_cs_v </td><td> $_cb_v </td></tr>"
done
echo "</table>"

echo "<table>"
echo -n "<tr>"
echo -n "<th> CUDA Release </th>"
echo -n "<th> Size (K) </th>"
echo -n "<th> cuSPARSE Size</th>"
echo -n "<th> cuBLAS Size</th>"
echo -n "<th> nvcc Size</th>"
echo -n "<th> cuFFT Size</th>"
echo -n "<th> cuRAND Size</th>"
echo -n "<th> cuSOLVER Size</th>"
echo -n "<th> npp Size</th>"
echo -n "<th> Nsight Compute</th>"
echo -n "<th> Nsight Systems</th>"
echo -n "<th> cuPTI Size</th>"
echo -n "<th> CUDA GDB Size</th>"
echo -n "<th> cudart Size</th>"
echo -n "<th> nvrtc Size </th>"
echo -n "<th> nsight Size </th>"
echo -n "<th> driver Size </th>"
echo "</tr>"
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
    echo -n "<tr><td> $_r </td>"
    echo -n "<td> $_c_s </td>"
    echo -n "<td> $_cs_s ("$(pct $_cs_s $_c_s)"&#37) </td>"
    echo -n "<td> $_cb_s ("$(pct $_cb_s $_c_s)"&#37) </td>"
    echo -n "<td> $_nvcc_s ("$(pct $_nvcc_s $_c_s)"&#37) </td>"
    echo -n "<td> $_cufft_s ("$(pct $_cufft_s $_c_s)"&#37) </td>"
    echo -n "<td> $_curand_s ("$(pct $_curand_s $_c_s)"&#37) </td>"
    echo -n "<td> $_cusolver_s ("$(pct $_cusolver_s $_c_s)"&#37) </td>"
    echo -n "<td> $_npp_s ("$(pct $_npp_s $_c_s)"&#37) </td>"
    echo -n "<td> $_nsight_compute_s ("$(pct $_nsight_systems_s $_c_s)"&#37) </td>"
    echo -n "<td> $_nsight_systems_s ("$(pct $_nsight_compute_s $_c_s)"&#37) </td>"
    echo -n "<td> $_cupti_s ("$(pct $_cupti_s $_c_s)"&#37) </td>"
    echo -n "<td> $_gdb_s ("$(pct $_gdb_s $_c_s)"&#37) </td>"
    echo -n "<td> $_cudart_s ("$(pct $_cudart_s $_c_s)"&#37) </td>"
    echo -n "<td> $_nvrtc_s ("$(pct $_nvrtc_s $_c_s)"&#37) </td>"
    echo -n "<td> $_nsight_s ("$(pct $_nsight_s $_c_s)"&#37) </td>"
    echo -n "<td> $_driver_s ("$(pct $_driver_s $_c_s)"&#37) </td>"
    echo "</tr>"
done
echo "</table>"



echo -n "CUDA Release,"
echo -n "cuSPARSE,"
echo -n "cuBLAS,"
echo -n "nvcc,"
echo -n "cuFFT,"
echo -n "cuRAND,"
echo -n "cuSOLVER,"
echo -n "npp,"
echo -n "Nsight Compute,"
echo -n "Nsight Systems,"
echo -n "cuPTI,"
echo -n "CUDA GDB,"
echo -n "cudart,"
echo -n "nvrtc,"
echo -n "nsight,"
echo -n "driver,"
echo ""
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
    echo -n "$_r,"
    echo -n "$_cs_s,"
    echo -n "$_cb_s,"
    echo -n "$_nvcc_s,"
    echo -n "$_cufft_s,"
    echo -n "$_curand_s,"
    echo -n "$_cusolver_s,"
    echo -n "$_npp_s,"
    echo -n "$_nsight_compute_s,"
    echo -n "$_nsight_systems_s,"
    echo -n "$_cupti_s,"
    echo -n "$_gdb_s,"
    echo -n "$_cudart_s,"
    echo -n "$_nvrtc_s,"
    echo -n "$_nsight_s,"
    echo -n "$_driver_s,"
    echo ""
done
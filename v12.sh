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
    version_re='/([0-9]+\.[0-9]+\.[0-9]+)/'
    if [[ $1 =~ $version_re ]]; then
        echo ${BASH_REMATCH[1]}
        version=${BASH_REMATCH[1]}
    else
        echo "no match"
        exit 1
    fi
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
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname/libcusparse | cut -f1)
    echo $size B
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
    fname=$(basename $1)
    dirname="${fname%.*}"
    size=$(du -s $dirname/libcublas | cut -f1)
    echo $size B
}

# echo "downloading"
# nice -n20 parallel -j${SIMULTANEOUS_DOWNLOADS} download {} ::: ${URLS[*]}

# echo "extracting"
# nice -n20 parallel -j${SIMULTANEOUS_EXTRACTS} extract {} ::: ${URLS[*]}

echo "<table>"
echo "<tr><th> CUDA Release </th><th> cuSPARSE Version </th><th> cuSPARSE Size (B) </th></tr>"
for url in ${URLS[*]}; do
    _r=$(cuda_release "$url")
    _cs_v=$(cusparse_version "$url")
    _cs_s=$(cusparse_size "$url")
    echo "<tr><td> $_r </td><td> $_cs_v </td><td> $_cs_s </td></tr>"
done
echo "</table>"

echo "<table>"
echo "<tr><th> CUDA Release </th><th> cuBLAS Version </th><th> cuBLAS Size (B) </th></tr>"
for url in ${URLS[*]}; do
    _r=$(cuda_release "$url")
    _cb_v=$(cublas_version "$url")
    _cb_s=$(cublas_size "$url")
    echo "<tr><td> $_r </td><td> $_cb_v </td><td> $_cb_s </td></tr>"
done
echo "</table>"

set -eou pipefail

echo "downloading"

URLS=(
https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run
https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux.run
https://developer.download.nvidia.com/compute/cuda/12.2.2/local_installers/cuda_12.2.2_535.104.05_linux.run
)

function download {
    version_re='/([0-9]+\.[0-9]+\.[0-9]+)/'
    echo $1
    if [[ $1 =~ $version_re ]]; then

        echo ${BASH_REMATCH[1]}
        version=${BASH_REMATCH[1]}
        # echo ${BASH_REMATCH[*]}

    else
        echo "no match"
        exit 1
    fi
    fname=$(basename $1)
    wget --no-check-certificate -c $1
}
export -f download # export to subshells


function extract {
    echo $1
    fname=$(basename $1)
    dirname="${fname%.*}"
    echo "$1 -> $dirname"
    rm -rf $dirname
    $SHELL $fname --extract=$PWD/$dirname
}
export -f extract # export to subshells

echo "downloading"
parallel -j2 download {} ::: ${URLS[*]}

echo "extracting"
parallel extract {} ::: ${URLS[*]}

# find all cuda versions
for url in ${URLS[*]}; do
    echo $url
    fname=$(basename $url)
    dirname="${fname%.*}"

    grep -r 'e CUSPARSE_VER_' $dirname;
done


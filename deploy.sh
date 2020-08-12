# clean directory first



setupFun(){

  pgrep lotus | xargs kill -s QUIT

  rm -rf "${2:?}" expect -y
  echo 'removed sealer data'

  rm -rf ~/.lotusstorage
  echo 'removed .lotusstorage'
  rm -rf ~/.lotus
  echo 'removed .lotus'
  rm -rf ~/.lotusstorage
  echo 'removed .genesis-sectors'

  rm "$1"/localnet.json
  echo 'removed localnet.json'
  rm "$1"/dev.gen
  echo 'removed dev.gen'

  echo 'kill k8s jobs'
  kubectl delete job $(kubectl get job -o=jsonpath='{.items[].metadata.name}')

  # setup env
  cd "$1" || exit
  echo 'setup pre seal, local.json, run node'
  "$1"/lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 && "$1"/lotus-seed genesis new localnet.json
  "$1"/lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json
  "$1"/lotus daemon --lotus-make-genesis=dev.gen --genesis-template=localnet.json --bootstrap=false &
  sleep 10s

  echo 'setup wallet'
  "$1"/lotus wallet import ~/.genesis-sectors/pre-seal-t01000.key
  sleep 10s

  echo 'setup miner'
  "$1"/lotus-storage-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync
}


if [[ ! -n "$1" ]] ||[[ ! -n "$2" ]] ;then
    echo "you have not input directory include lotus lotus-seed and lotus-storage-miner"
else
    setupFun "$1" "$2"
fi


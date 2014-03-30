import 'basenode.pp'

node default inherits basenode {
  include go-ethereum
}

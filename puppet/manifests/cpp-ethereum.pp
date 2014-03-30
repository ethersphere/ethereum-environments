import 'basenode.pp'

node default inherits basenode {
  include cpp-ethereum
}
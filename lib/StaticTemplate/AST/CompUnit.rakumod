unit class StaticTemplate::AST::CompUnit;

has $.main;
has %.macros;

method gist {
  [
    "{ $?CLASS.^name}:",
    |%.macros.kv.map(-> Str() $name, $list {
      "$name:".indent(2),
      $list.gist.indent(4),
    }),
    "__MAIN__:".indent(2),
    $!main.gist.indent(4),
  ].join: "\n"
}

method run {
  my %*SCOPE;
  $.main.run
}

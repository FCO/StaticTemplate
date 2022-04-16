unit class StaticTemplate::AST::Variable;

has Str $.name;

method gist {
  [
    "{ $?CLASS.^name}:",
    $!name.indent(2),
  ].join: "\n"
}

method run {
  %*SCOPE{ $!name } // ""
}

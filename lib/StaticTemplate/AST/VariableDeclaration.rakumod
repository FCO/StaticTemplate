use StaticTemplate::Type;
unit class StaticTemplate::AST::VariableDeclaration;

has Str                  $.name;
has                      $.initial-value;
has StaticTemplate::Type $.type;

submethod BUILD(:$!name, :$!initial-value, :$type = "any") {
  if $type ~~ Str {
    $!type .= new: :name($type)
  } else {
    $!type = $type
  }
}

method gist {
  [
    "{ $?CLASS.^name}:",
    "name:".indent(2),
    $!name.indent(4),
    "initial value:".indent(2),
    $!initial-value.gist.indent(4),
  ].join: "\n"
}

method run {
  %*SCOPE{ $!name } = .run with $!initial-value;
  ""
}

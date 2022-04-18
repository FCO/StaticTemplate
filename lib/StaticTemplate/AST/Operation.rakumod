use StaticTemplate::Type;
unit class StaticTemplate::AST::Operation;

has     $.left;
has     $.right;
has Str $.op;

method gist {
  [
    "{ $?CLASS.^name }:",
    "op: $!op".indent(2),
    "left:\n$!left.gist().indent(2)".indent(2),
    "right:\n$!right.gist().indent(2)".indent(2),
  ].join: "\n"
}

method run {
  my $left  = $!left.?run  // $!left;
  my $right = $!right.?run // $!right;

  self.run-op: $!op, $left, $right
}

multi method run-op("+", $left, $right) { $left + $right }
multi method run-op("-", $left, $right) { $left - $right }
multi method run-op("*", $left, $right) { $left * $right }
multi method run-op("/", $left, $right) { $left / $right }

multi method run-op("==", $left, $right) { $left == $right }

method type {
  if $!op eq ("=="|"!="|">"|">="|"<"|"<=") {
    return StaticTemplate::Type.type: "boolean"
  }
  if $!op eq "+" && ($!left|$!right).type.isa: "string" {
    return StaticTemplate::Type.type: "string"
  }
  return StaticTemplate::Type.type: "number"
}
